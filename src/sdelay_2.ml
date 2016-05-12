open Cil
open Pretty
open Ktcutil

module E = Errormsg
module L = List

module IH = Inthash  
module DF = Dataflow 
module AV = Avail

let debug = ref false


let findOrCreateFunc f name t =
  let rec search glist =
    match glist with
        GVarDecl(vi,_) :: rest when isFunctionType vi.vtype
          && vi.vname = name -> vi
      | _ :: rest -> search rest (* tail recursive *)
      | [] -> (*not found, so create one *)
          let new_decl = makeGlobalVar name t in
          f.globals <- GVarDecl(new_decl, locUnknown) :: f.globals;
          new_decl
  in
    search f.globals



let findStructType (f : file) (typname : string) : typ =
  let rec search gl =
        match gl with
        | [] -> E.s (E.error "Type not found: %s" typname)
        | GCompTag(ci,_) :: _     when ci.cname = typname -> TComp(ci,[])
        | GCompTagDecl(ci,_) :: _ when ci.cname = typname -> TComp(ci,[])
        | _ :: rest -> search rest
  in
        search f.globals


let findCompinfo (f : file) (ciname : string) : compinfo =
    let rec search glist =
        match glist with
        | [] -> raise(Failure "Compinfo not found")
        | GCompTag(ci, _) :: _ when ci.cname = ciname -> ci
        | GCompTagDecl(ci, _) :: _ when ci.cname = ciname -> ci
        | _ :: rest -> search rest
   in
      search f.globals

let findTypeinfo (f : file) (tpname : string) : typeinfo =
    let rec search glist =
        match glist with
        | [] -> raise(Failure "typeinfo not found")
        | GType(tp, _) :: _ when tp.tname = tpname -> tp
        | _ :: rest -> search rest
   in
      search f.globals

let findVarG (f : file) (viname : string) : varinfo =
    let rec search glist =
        match glist with
        | [] -> raise(Failure "Var not found")
        | GVarDecl(vi, _) :: _ when vi.vname = viname -> vi
        | _ :: rest -> search rest
   in
      search f.globals

type functions = {
  mutable sdelay_init : varinfo;
  mutable sdelay_end  : varinfo;
  mutable fdelay_init :varinfo;
  mutable timer_create : varinfo;
  mutable sig_setjmp : varinfo;
  mutable start_timer : varinfo;
}

let dummyVar = makeVarinfo false "_sdelay_foo" voidType

let sdelayfuns = {
  sdelay_init = dummyVar;
  sdelay_end  = dummyVar;
  fdelay_init = dummyVar;
  timer_create = dummyVar;
  sig_setjmp = dummyVar;
  start_timer = dummyVar;
}



let sdelay_init_str = "ktc_sdelay_init"
let sdelay_end_str   = "ktc_start_time_init"
let fdelay_init_str = "ktc_fdelay_init"
let timer_create_str  = "create_timer"
let sig_setjmp_str = "__sigsetjmp" 
let start_timer_str = "start_timer_fdelay" 

let sdelay_function_names = [
  sdelay_init_str;
  sdelay_end_str;
  fdelay_init_str;
  timer_create_str;
  sig_setjmp_str;
  start_timer_str;
]


let isSdelayFun (name : string) : bool =
  L.mem name sdelay_function_names

let initSdelayFunctions (f : file)  : unit =
  let focf : string -> typ -> varinfo = findOrCreateFunc f in
  let init_type = TFun(intType, Some["unit", charPtrType, [];],
                     false, [])
  in
  let end_type = TFun(intType, Some["intrval", intType, [];],
                     false, [])
  in
  sdelayfuns.sdelay_init <- focf sdelay_init_str init_type;
  sdelayfuns.sdelay_end <- focf sdelay_end_str   end_type;
  sdelayfuns.fdelay_init <- focf fdelay_init_str init_type;
  sdelayfuns.timer_create <- focf timer_create_str init_type;
  sdelayfuns.sig_setjmp <- focf   sig_setjmp_str init_type;
  sdelayfuns.start_timer <- focf  start_timer_str init_type


let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location)  =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.sdelay_init, [intervl;tunit;s;], loc)]

let makeSdelayEndInstr (structvar : varinfo) (timervar : varinfo) (tp : varinfo)=
  let s =  mkAddrOf((var structvar)) in
  let start_time_init = Call(None, v2e sdelayfuns.sdelay_end, [s;], locUnknown) in 
  let t =  mkAddrOf((var timervar)) in
  let handlrt = mkAddrOf((var tp)) in
  let timer_init = Call(None, v2e sdelayfuns.timer_create, [t;handlrt;], locUnknown) in
  [mkStmtOneInstr start_time_init; mkStmtOneInstr timer_init]

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;], loc)]

let maketimerfdelayStmt structvar argL tpstructvar timervar=
	 let offset' = match tpstructvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "env", NoOffset) in	
	let buf = Lval(Var tpstructvar, offset') in
	let i = Cil.one in
	let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in 
	let intr, tunit, timr, s = L.hd argL, time_unit, v2e timervar, v2e structvar in
	let sigInt = Call(None, v2e sdelayfuns.sig_setjmp, [buf;i;], locUnknown) in
	let startTimer = Call(None, v2e sdelayfuns.start_timer, [intr; tunit;timr;s;], locUnknown) in
	  [mkStmtOneInstr sigInt; mkStmtOneInstr startTimer ]

let instrTimingPoint (i : instr) : bool = 
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "fdelay") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "sdelay")  -> true
    | _ -> false

let instrTimingPointAftr (i : instr) : bool =
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "ktc_sdelay_init") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "ktc_fdelay_init")  -> true
    | _ -> false
(*
let getFirmInterval s =
	match s.kind with
	|Instr il when List.hd il = Call (_, Lval (Var vf, _), argList, _) -> argList
*)
let rec splitTimeBlocks aux il =
        match il with
        | h::t when ((instrTimingPoint h) && List.length t <> 0)  -> begin 
						if List.length aux > 0 then 
							List.append ([ mkStmt (Instr (List.rev aux)); mkStmtOneInstr h]) (splitTimeBlocks [] t)
						else
							List.append [mkStmtOneInstr h] (splitTimeBlocks [] t)
					  end 
	| h::t when ((instrTimingPoint h) && List.length t = 0) -> begin 
					if List.length aux > 0 then
						List.append  [mkStmt (Instr (List.rev aux))] [mkStmtOneInstr h]
					else
						 [mkStmtOneInstr h] 
        					end
	| h::t when not (instrTimingPoint h) -> splitTimeBlocks (h :: aux) t
        | [] -> [mkStmt (Instr (List.rev aux))]

let makeTimeBlocks il = 
        splitTimeBlocks [] il
 	
class timingAnalysis filename  = object(self)
  inherit nopCilVisitor

       method vstmt s =
	match s.skind with 
	Instr (il) -> begin
		if (List.exists instrTimingPoint il) then 
			let list_of_stmts = makeTimeBlocks il in
		let block = mkBlock list_of_stmts in
		s.skind <- Block block;
		ChangeTo(s)
	else
		SkipChildren
	end 
	|_ -> DoChildren  
end

let getInstr s =
	match s.skind with
	|Instr il -> match List.hd il with 
			|Call(_,Lval(Var vi,_),argList,loc)  -> argList 
	
class sdelayReportAdder filename fdec structvar tpstructvar timervar data fname  = object(self)
  inherit nopCilVisitor


			
       method vinst (i :instr) =
        let sname = "fdelay" in
        let action [i] =
        match i with
        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = fname) -> makeSdelayInitInstr structvar argList loc
        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = sname) -> makeFdelayInitInstr structvar argList loc
        |_ -> [i]
        in
        ChangeDoChildrenPost([i], action)

	method vstmt s =
	let action s =
        match s.skind with
        Instr il ->
                if  instrTimingPointAftr (List.hd il)  && (checkFirmSuccs data s) then
                let firmSuccInst = retFirmSucc s data in
                let intr = getInstr firmSuccInst in
                let addthisTo = maketimerfdelayStmt structvar intr tpstructvar timervar in  
                let changStmTo = mkStmt s.skind  :: addthisTo in 
                let block = mkBlock changStmTo in
                s.skind <- Block block;
                s
		else 
		s
        
        |_ -> s
	in ChangeDoChildrenPost(s, action)


end



class correctnessAnalysis f = object(self)
	inherit nopCilVisitor 

	method vfunc(fdec: fundec) =
	checkTPSucc fdec;
	checkAvailOfStmt fdec;
	DoChildren 

(*	method vstmt (s :stmt) =
	match s.skind with 
	|Instr (il) -> begin 
			if (List.length il = 1 &&  instrTimingPoint (List.hd il)) then
			varAvailable s; fdelayWorks s
		       end; DoChildren
	|_ -> DoChildren 
*)				
end
class sdelayFunc filename fname = object(self)
        inherit nopCilVisitor

        method vfunc (fdec : fundec) =
		Cfg.computeFileCFG filename; 
   		Cfg.printCfgFilename (fdec.svar.vname ^ ".dot") fdec;
		 Cfg.clearFileCFG filename;
(*		Cfg.cfgFunPrint (fdec.svar.vname^".dot") fdec; 
	        computeAvail fdec; 
		computeTPSucc fdec; 
		computeAvail  fdec; 
		let data = checkTPSucc fdec in *) 
		let timername = "timer_t" in
		let ftimer =  findTypeinfo filename timername in 
		let ftimer = makeLocalVar fdec "ktctimer" (TNamed(ftimer, [])) in             
		let structname = "timespec" in
                let ci = findCompinfo filename structname in
                let structvar = makeLocalVar fdec "start_time" (TComp(ci,[])) in
		let tpstructvarinfo = findCompinfo filename "tp_struct" in 
		let tpstructvar = makeLocalVar fdec "tp" (TComp(tpstructvarinfo,[])) in
		let init_start = makeSdelayEndInstr structvar ftimer tpstructvar  in
		let data = checkTPSucc fdec in 
		let y = checkAvailOfStmt fdec in 
		let modifysdelay = new sdelayReportAdder filename fdec structvar tpstructvar ftimer data fname  in
                fdec.sbody <- visitCilBlock modifysdelay fdec.sbody; 
		fdec.sbody.bstmts <- List.append init_start fdec.sbody.bstmts; 
                ChangeTo(fdec)

end
let isErrorFree f =
	let cVisitor = new correctnessAnalysis f in 
	visitCilFile cVisitor f

let timing_basic_block f =
  let thisVisitor = new timingAnalysis f in
  visitCilFileSameGlobals thisVisitor f  


let sdelay (f : file) : unit =
initSdelayFunctions f; timing_basic_block f; (*isErrorFree f;*) 
let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
  visitCilFile vis f 
(*
let sdelay (f : file) : unit =
  initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
  visitCilFile vis f*)
