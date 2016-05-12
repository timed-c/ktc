open Cil
open Pretty
open Ktcutil

module E = Errormsg
module L = List

module IH = Inthash  
module DF = Dataflow 
module AV = Avail

let debug = ref false
let labelHash =  IH.create 64


type functions = {
  mutable sdelay_init : varinfo;
  mutable start_timer_init : varinfo;
  mutable fdelay_init :varinfo;
  mutable timer_create : varinfo;
  mutable sig_setjmp : varinfo;
  mutable fdelay_start_timer : varinfo;
}

let dummyVar = makeVarinfo false "_sdelay_foo" voidType

let sdelayfuns = {
  sdelay_init = dummyVar;
  start_timer_init  = dummyVar;
  fdelay_init = dummyVar;
  timer_create = dummyVar;
  sig_setjmp = dummyVar;
  fdelay_start_timer = dummyVar;
}



let sdelay_init_str = "ktc_sdelay_init"
let start_timer_init_str   = "ktc_start_time_init"
let fdelay_init_str = "ktc_fdelay_init"
let timer_create_str  = "ktc_create_timer"
let sig_setjmp_str = "__sigsetjmp" 
let fdelay_start_timer_str = "ktc_fdelay_start_timer" 

let sdelay_function_names = [
  sdelay_init_str;
  start_timer_init_str;
  fdelay_init_str;
  timer_create_str;
  sig_setjmp_str;
  fdelay_start_timer_str;
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
  sdelayfuns.start_timer_init <- focf start_timer_init_str   end_type;
  sdelayfuns.fdelay_init <- focf fdelay_init_str init_type;
  sdelayfuns.timer_create <- focf timer_create_str init_type;
  sdelayfuns.sig_setjmp <- focf   sig_setjmp_str init_type;
  sdelayfuns.fdelay_start_timer <- focf  fdelay_start_timer_str init_type


let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location)  =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.sdelay_init, [intervl;tunit;s;], loc)]

let makeSdelayEndInstr (structvar : varinfo) (timervar : varinfo) (tp : varinfo)=
  let s =  mkAddrOf((var structvar)) in
  let start_time_init = Call(None, v2e sdelayfuns.start_timer_init, [s;], locUnknown) in 
  let t =  mkAddrOf((var timervar)) in
  let handlrt = mkAddrOf((var tp)) in
  let timer_init = Call(None, v2e sdelayfuns.timer_create, [t;handlrt;], locUnknown) in
  [mkStmtOneInstr start_time_init; mkStmtOneInstr timer_init]

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;], loc)]

let ifBlockFunc goto_stmt retjmp =
	(*goto_stmt.skind <- Goto(ref goto_stmt, locUnknown);*) 
	let block_goto = mkBlock[goto_stmt] in
	let block_else = mkBlock[] in
	let ifcond = If((v2e retjmp), block_goto, block_else, locUnknown) in
		(mkStmt ifcond)



let getvaridStmt s =
        match s.skind with
        |Instr il when il <> []-> match List.hd il with
                        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "fdelay")  -> vi.vid
			|_ -> E.s(E.bug "Error: label"); -1

let findgoto data s =
        let id = getvaridStmt s in
         try IH.find data id
                with Not_found -> E.s(E.bug "%d" id)

let maketimerfdelayStmt structvar argL tpstructvar timervar retjmp firmStmt =
	 let offset' = match tpstructvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "env", NoOffset) in	
	let buf = Lval(Var tpstructvar, offset') in
	let i = Cil.one in
	let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in 
	let intr, tunit, timr, s = L.hd argL, time_unit, v2e timervar, v2e structvar in
	let sigInt = Call(Some(var retjmp), v2e sdelayfuns.sig_setjmp, [buf;i;], locUnknown) in
	let letjmpto = findgoto labelHash firmStmt in 
	let goto_label = mkStmt (Goto(ref letjmpto, locUnknown))  in 
	let ifBlock = ifBlockFunc goto_label retjmp  in
	let startTimer = Call(None, v2e sdelayfuns.fdelay_start_timer, [intr; tunit;timr;s;], locUnknown) in
	  [mkStmtOneInstr sigInt; ifBlock; mkStmtOneInstr startTimer ]

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
	|Instr il when il <> []-> match List.hd il with 
			|Call(_,Lval(Var vi,_),argList,loc)  -> argList 
	
class sdelayReportAdder filename fdec structvar tpstructvar timervar ret_jmp data fname  = object(self)
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
        Instr il when il <> [] -> if instrTimingPointAftr (List.hd il) && (checkFirmSuccs data s) then 
		         (*let label_stmt = mkStmt (Instr []) in
                         label_stmt.labels <- [Label(string_to_int s.sid,locUnknown,false)] ;*)
                	  (*let tname = E.log "out here fdelay" in*)
			 let firmSuccInst = retFirmSucc s data in
                	 let intr = getInstr firmSuccInst in
                	 let addthisTo = maketimerfdelayStmt structvar intr tpstructvar timervar ret_jmp firmSuccInst in  
                	 let changStmTo = (mkStmt s.skind)  :: addthisTo in
                	 let block = mkBlock  changStmTo in
                	s.skind <- Block block;
                	s
		else
			s
		 
        |_ -> s
	in ChangeDoChildrenPost(s, action)


end

	

class correctnessAnalysis fdec = object(self)
	inherit nopCilVisitor 
	method vstmt (s :stmt) =
	let action s =
	match s.skind with 
	|Instr (il) ->  
			if (List.length il = 1 &&  instrTimingPoint (List.hd il)) && (isFirm (List.hd il)) then
			let label_name = "_"^string_of_int(s.sid) in
			let label_no =  getvaridStmt s in
			let label_stmt = mkStmt (Instr []) in 
                		label_stmt.labels <- [Label(label_name,locUnknown,false)]; (*E.log "%d" label_no;*) IH.add labelHash label_no label_stmt; 
			let changStmTo = List.append [mkStmt s.skind] [label_stmt] in
			let block = mkBlock  changStmTo in
                	s.skind <- Block block ;
                	s
                	else
                	s

        |_ -> s
        in ChangeDoChildrenPost(s, action)

end

let isErrorFree f =
	IH.clear labelHash; (*E.log "jgd-jgd-jgd iserroefree";*) 
        let cVisitor = new correctnessAnalysis f in
        visitCilFile cVisitor f


class sdelayFunc filename fname = object(self)
        inherit nopCilVisitor

        method vfunc (fdec : fundec) =
		Cfg.computeFileCFG filename; 
   		Cfg.printCfgFilename (fdec.svar.vname ^ ".dot") fdec;
		 Cfg.clearFileCFG filename;
	(*	Cfg.cfgFunPrint (fdec.svar.vname^".dot") fdec; 
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
		let ret_jmp = makeLocalVar fdec "retjmp" intType in
		let init_start = makeSdelayEndInstr structvar ftimer tpstructvar  in
		let data = checkTPSucc fdec in 
		let y = checkAvailOfStmt fdec in
		(*let y' = isErrorFree filename in*)
		let modifysdelay = new sdelayReportAdder filename fdec structvar tpstructvar ftimer ret_jmp data fname  in
                fdec.sbody <- visitCilBlock modifysdelay fdec.sbody;
		fdec.sbody.bstmts <- List.append init_start fdec.sbody.bstmts; 
                ChangeTo(fdec)

end

let timing_basic_block f =
  let thisVisitor = new timingAnalysis f in
  visitCilFileSameGlobals thisVisitor f  


let sdelay (f : file) : unit =
initSdelayFunctions f; timing_basic_block f;  Cfg.computeFileCFG f;isErrorFree f; Cfg.clearFileCFG f; 
let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
  visitCilFile vis f 
(*
let sdelay (f : file) : unit =
  initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
  visitCilFile vis f*)
