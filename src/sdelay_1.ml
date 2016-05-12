open Cil
open Pretty
open Ktcutil

module E = Errormsg
module L = List

module IH = Inthash  
module DF = Dataflow 


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
}

let dummyVar = makeVarinfo false "_sdelay_foo" voidType

let sdelayfuns = {
  sdelay_init = dummyVar;
  sdelay_end  = dummyVar;
  fdelay_init = dummyVar;
  timer_create = dummyVar;
  sig_setjmp = dummyVar;
}



let sdelay_init_str = "ktc_sdelay_init"
let sdelay_end_str   = "ktc_start_time_init"
let fdelay_init_str = "ktc_fdelay_init"
let timer_create_str  = "create_timer"
let sig_setjmp_str = "sigsetjmp" 

let sdelay_function_names = [
  sdelay_init_str;
  sdelay_end_str;
  fdelay_init_str;
  timer_create_str;
  sig_setjmp_str;
]

(*
type tpmap = int * (Cil.stmt * Cil.exp)

let id_of_tm   (tm : tpmap) : int  = fst tm
let st_of_tm   (tm : tpmap) : stmt = tm |> snd |> fst
let intr_of_tm (tm : tpmap) : Cil.exp  = tm |> snd |> snd


let tpmap_list_pretty () (tmap : tpmap list) =
	let tm = L.hd tmap in
	d_exp () (intr_of_tm tm) 
   
  

let tpmap_equal (tm1 : tpmap) (tm2 : tpmap) : bool =
  (id_of_tm tm1) = (id_of_tm tm2) &&
  (intr_of_tm tm1) = (intr_of_tm tm2)

let tpmap_list_equal (tpl1 : tpmap list) (tpl2 : tpmap list) : bool =
  let sort = L.sort (fun (id1,_) (id2,_) -> compare id1 id2) in
  list_equal tpmap_equal (sort tpl1) (sort tpl2)

let intr_combine intr1 intr2 : Cil.exp = 
	if intr1 = Cil.mone then
		intr2
	else
		intr1

let tpmap_combine (tm1 : tpmap) (tm2 : tpmap) : tpmap option =
  match tm1, tm2 with
  | (id1, _), (id2, _) when id1 <> id2 -> None
  | (id1, (s1, k1)), (_,(_,k2)) -> Some(id1,(s1, intr_combine k1 k2))


let tpmap_list_combine_one (tml : tpmap list) (tm : tpmap) : tpmap list =
  let id = id_of_tm tm in
  if L.mem_assoc id tml then
    let tm' = (id, L.assoc id tml) in
    let tm'' = forceOption (tpmap_combine tm tm') in
    tm'' :: (L.remove_assoc (id_of_tm tm) tml)
  else tm :: tml


let tpmap_list_combine (tml1 : tpmap list) (tml2 : tpmap list) : tpmap list =
  L.fold_left tpmap_list_combine_one tml1 tml2


let tpmap_list_replace (tml : tpmap list) (tm : tpmap) : tpmap list =
  tm :: (L.remove_assoc (id_of_tm tm) tml)


		 
let isTimingPoint il =
	match L.hd il with 
		|Call(_,Lval(Var vi,_),_,_) when (vi.vname = "sdelay") -> true
 		|Call(_,Lval(Var vi,_),_,_) when (vi.vname = "fdelay") -> true
		|_ -> false

let isStmTimingPoint s =
        match s.skind with
        |Instr il when (isTimingPoint il = true )-> true
        |Instr il when (isTimingPoint il) = false -> false
        | _ -> false


let collectTimingPoint fd =
	let stmtsOfFun = fd.sallstmts in
	let timingPointStm = L.filter isStmTimingPoint stmtsOfFun in
	L.map (fun s -> (s.sid, (s, Cil.mone)))  timingPointStm

let timingSucc ts =
        let tSucc = L.filter isStmTimingPoint ts.succs in
        let sort = L.sort (fun s1 s2 -> compare s1.sid s2.sid) in
        let tims =  L.hd (sort tSucc) in
	match tims.skind with 
	| Instr il -> L.hd il
	|_ -> raise(Failure "Something is very wrong") 

	
let tpmap_list_handle_stmt (s: stmt) (tml : tpmap list) : tpmap list =
        if isStmTimingPoint s then begin
        let ti  =  timingSucc s in
         match ti with
         |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "fdelay") -> tpmap_list_replace tml (s.sid, (s, L.hd argList))
         | _ -> tml
        end
        else
        tml

module TimingPointDF = struct

  let name = "TimingPoint"
  let debug = debug
  type t = tpmap list
  let copy tml = tml
  let stmtStartData = IH.create 64
  let pretty = tpmap_list_pretty
  let computeFirstPredecessor stm tml = tml


  let combinePredecessors (s : stmt) ~(old : t) (ll : t) =
    if tpmap_list_equal old ll then None else
    Some(tpmap_list_combine old ll)

  let doInstr (i : instr) (ll : t) = DF.Default

  let doStmt (stm : stmt) (ll : t) = 
  	let action = tpmap_list_handle_stmt stm ll in
	DF.SUse action

  let doGuard c ll = DF.GDefault
  let filterStmt stm = true

end


module TimingPoint = DF.ForwardsDataFlow(TimingPointDF)


let computeTimingPoint (fd : fundec) : unit =
  Cfg.clearCFGinfo fd;
  ignore(Cfg.cfgFun fd);
  let first_stmt = L.hd fd.sbody.bstmts in
  let tml = collectTimingPoint fd in
  IH.clear TimingPointDF.stmtStartData;
  IH.add TimingPointDF.stmtStartData first_stmt.sid tml;
  TimingPoint.compute [first_stmt]

let getTimingPoints (sid: int) : tpmap list option = 
  try Some(IH.find TimingPointDF.stmtStartData sid)
  with Not_found -> None


let instrTimingPoint (s ) (tml : tpmap list) : tpmap list list =
  let proc_one hil s =
    match hil with
    | [] -> (tpmap_list_handle_stmt s tml) :: hil
    | tml':: rst as l -> (tpmap_list_handle_stmt s tml') :: l
  in
   L.fold_left proc_one [tml] s


class tmlVisitorClass = object(self)
  inherit nopCilVisitor

  val mutable sid           = -1
  val mutable state_list    = []
  val mutable current_state = None

  method vstmt stm =
    sid <- stm.sid;
    begin match getTimingPoints sid with
    | None -> current_state <- None
    | Some tml -> begin
      match stm.skind with
      | Instr il ->
        current_state <- None;
        state_list <- instrTimingPoint [stm] tml
      | _ -> current_state <- None
    end end;
    DoChildren


  method get_cur_tml () =
    match current_state with
    | None -> getTimingPoints sid
    | Some tml -> Some tml

end

class stmntUseReporterClass = object(self)
  inherit tmlVisitorClass as super

 method vstmt (s :stmt ) =
	match self#get_cur_tml () with 
	|None -> SkipChildren
	|Some tml -> begin
      if L.mem_assoc s.sid tml then begin
        let tm = (s.sid, L.assoc s.sid tml) in
        E.log "%a: %a\n" d_loc (!currentLoc) tpmap_list_pretty [tm]
      end;
      SkipChildren
    end

end


let timingPointAnalysis (fd : fundec) : unit =
  computeTimingPoint fd;
  let vis = ((new stmntUseReporterClass) :> nopCilVisitor) in
  ignore(visitCilFunction vis fd)
*)









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
  sdelayfuns.sig_setjmp <- focf   sig_setjmp_str init_type


let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.sdelay_init, [intervl;tunit;s;], loc)]

let makeSdelayEndInstr (structvar : varinfo) (timervar : varinfo) =
  let s =  mkAddrOf((var structvar)) in
  let start_time_init = Call(None, v2e sdelayfuns.sdelay_end, [s;], locUnknown) in 
  let t =  mkAddrOf((var timervar)) in
  let timer_init = Call(None, v2e sdelayfuns.timer_create, [t;], locUnknown) in
  [mkStmtOneInstr start_time_init; mkStmtOneInstr timer_init]

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;], loc)]

let maketimerfdelayStmt loc s il fdelayIntr =
	let buf = mkString "env" in
	 let sigInt = Call(None, v2e sdelayfuns.sig_setjmp, [buf;], loc) in
	 sigInt ::  il
	
	



(*
let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;], loc)]

*)
(*
let mark sl =
	match sl with 
	| hd::tl -> begin 
			match hd.skind with 
			|Instr il -> markTime hd il; mark tl
			|_ -> mark tl  
		   end
	| _ -> mark tl

let markTimingPoint s = 
	match s with 
		|Instr il = mark il
let addPrevTimingPoint s il timingPointList  =
		   match L.hd il with 
			|Call(_,Lval(Var vi,_),_,loc) when (vi.vname = fname) -> begin
										if fst L.hd timingPointList = dummyStmt then 
										  timingPointList <-  timingPointList ::(s, s.sid) 
										end
			|_ -> timingPointList.timingPoint
*)

(*
let mark st timingPoints id timerTime =
	if st.sid > id  then 
		st.sid
	else
		id 
*)	 
(*	
let findIntr s =
	match s.skind with
                   |Instr il ->begin
                        match L.hd il with
                        |Call(_,Lval(Var vi,_),argList ,loc) when vi.vname = "fdelay" -> L.hd argList
                        |Call(_,Lval(Var vi,_),_,loc) when vi.vname = "sdelay" -> Cil.zero
			|_ -> Cil.mone
			end
		  |_ -> Cil.mone

let rec addTimer s =
	match s with
	|h::t ->  if findIntr h <> Cil.mone then
			findIntr h 
		   else addTimer t
			
	|[] -> Cil.zero
*)
		 							   
(*
class fdelayReportAdder filename fdec timingPointList   = object(self)
  inherit nopCilVisitor
        method vstmt (s : stmt) =
	 let id = -1 in
        let timingPoints = (dummyStmt, -1) in
	match s.skind with 
	|Instr il  -> begin
			match L.hd il with 
			|Call(_,Lval(Var vi,_),argList,loc) when vi.vname = "fdelay" -> addPrevTimingPoint s s.preds timingPoints id L.hd argList; 
			timingPointList <- timingPoints :: timingPointList
		      end; DoChildren 
	| _ -> DoChildren
end
*)

(*
class timerAdder filename fdec structvar timervar  = object(self)
  inherit nopCilVisitor
        method vstmt (s ) =
	Cfg.clearFileCFG filename;
        Cfg.computeFileCFG filename;
        let fname = "fdelay" in
	let sname = "sdelay" in
	let fdelayIntr = addTimer s in
        let action s =
        match s.skind with
	|Instr il -> match L.hd il with  
        		|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = fname) -> if fdelayIntr <> Cil.zero then 
											  s.skind <- Block ( maketimerfdelayStmt filename s  fdelayIntr); s
        		|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = sname) -> if fdelayIntr <> Cil.zero then
                                                                                          s.skind <- Block (maketimerfdelayStmt filename s  fdelayIntr); s
        |_ -> s
        in
        ChangeDoChildrenPost(s, action)

end

*)


class sdelayReportAdder filename fdec structvar fname  = object(self)
  inherit nopCilVisitor

(*
	method vstmt (s ) =
        let fname = "fdelay" in
        let sname = "sdelay" in
        let fdelayIntr = Cil.mone in
        let action s  = begin
        match s.skind with
        |Instr il -> begin 
			match L.hd il with
                        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = fname) -> begin 
											 if fdelayIntr <> Cil.zero then
                                                                                        (* maketimerfdelayStmt loc s il fdelayIntr*) s.skind
											end
                        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = sname) -> begin
											if fdelayIntr <> Cil.zero then
                                                                                       s.skind (* maketimerfdelayStmt loc s il fdelayIntr*)
											end
        		|_ -> s.skind
			end;s
	|_ -> s
	end
        in
        ChangeDoChildrenPost(s, action)
*)
(*
	method vinst (i :instr) =
	let sname = "fdelay" in
        let action [i] =
        match i with
        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = fname) -> makeSdelayInitInstr structvar argList loc
	|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = sname) -> makeFdelayInitInstr structvar argList loc
	|_ -> [i]
        in
        ChangeDoChildrenPost([i], action)
*)		
end

class sdelayFunc filename fname = object(self)
        inherit nopCilVisitor

        method vfunc (fdec : fundec) =
		(*Cfg.computeFileCFG filename; *)
		Cfg.clearFileCFG filename;
		Cfg.computeFileCFG filename; 
   		Cfg.printCfgFilename (fdec.svar.vname ^ ".dot") fdec; 
(*		Cfg.cfgFunPrint (fdec.svar.vname^".dot") fdec; *)
 		let timername = "timer_t" in
		let ftimer =  findTypeinfo filename timername in 
		let ftimer = makeLocalVar fdec "ktctimer" (TNamed(ftimer, [])) in             
		let structname = "timespec" in
                let ci = findCompinfo filename structname in
                let structvar = makeLocalVar fdec "start_time" (TComp(ci,[])) in
		let init_start = makeSdelayEndInstr structvar ftimer in 
                (*let modifysdelay = new sdelayReportAdder filename fdec structvar fname  in
                fdec.sbody <- visitCilBlock modifysdelay fdec.sbody; *)
		fdec.sbody.bstmts <- List.append init_start fdec.sbody.bstmts ; timingPointAnalysis fdec;
                ChangeTo(fdec)

end

let sdelay (f : file) : unit =
  initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
  visitCilFile vis f
