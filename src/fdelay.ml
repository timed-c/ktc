open Cil
open Pretty
open Ktcutil

module E = Errormsg
module L = List
module H = Hashtbl 
module IH = Inthash 
module HT = Hashtbl 
module DF = Dataflow 
module AV = Avail
module CG = Callgraph


let fprio = ref 5
let debug = ref false
let labelHash =  HT.create 64
let tp_id = ref 0
let all_task = ref []
let fifovarlst = ref []
	(*let all_read = ref []
	let all_write = ref[] *) 
let all_handles = ref []
	(*let readChanHash = HT.create 34 
	let writeChanHash = HT.create 34
	let simpsonChanSet = HT.create 34 
	*)
let fifoChanSet = HT.create 34


let critical_str = "critical"
let next_str = "next"
let task_str = "task"
let lv_str = "lvchannel"
let read_str = "read_block"
let write_str = "write_block"
let fifo_str = "fifochannel"
let init_str = "init_block"


let hasCriticalAttrs : attributes -> bool = hasAttribute critical_str

let isCriticalType (t : typ) : bool = t |> typeAttrs |> hasCriticalAttrs

let hasNextAttrs : attributes -> bool = hasAttribute next_str
	
let isNextType (t : typ) : bool = t |> typeAttrs |> hasNextAttrs

let hasTaskAttrs : attributes -> bool = hasAttribute task_str
	
let isTaskType (t : typ) : bool = t |> typeAttrs |> hasTaskAttrs

let hasLVAttrs : attributes -> bool = hasAttribute lv_str
	
let isLVType (t : typ) : bool = t |> typeAttrs |> hasLVAttrs

let hasReadAttrs : attributes -> bool = hasAttribute read_str
	
let isReadType (t : typ) : bool = t |> typeAttrs |> hasReadAttrs

let hasWriteAttrs : attributes -> bool = hasAttribute write_str
	
let isWriteType (t : typ) : bool = t |> typeAttrs |> hasWriteAttrs

let hasFIFOAttrs : attributes -> bool = hasAttribute fifo_str

let isFifoType (t : typ) : bool = t |> typeAttrs |> hasFIFOAttrs

let hasInitAttrs : attributes -> bool = hasAttribute init_str

let isInitType (t : typ) : bool = t |> typeAttrs |> hasInitAttrs


type functions = 
{
mutable sdelay_init : varinfo;
mutable start_timer_init : varinfo;
mutable fdelay_init :varinfo;
mutable timer_create : varinfo;
mutable sig_setjmp : varinfo;
mutable fdelay_start_timer : varinfo;
mutable critical_start : varinfo;
mutable critical_end : varinfo;
mutable task_create : varinfo;
mutable task_delete : varinfo;
mutable fifo_init : varinfo;
mutable fifo_read : varinfo;
mutable fifo_write : varinfo;
mutable ktc_start_scheduler : varinfo;
}

let dummyVar = makeVarinfo false "_sdelay_foo" voidType

let sdelayfuns = {
sdelay_init = dummyVar;
start_timer_init  = dummyVar;
fdelay_init = dummyVar;
timer_create = dummyVar;
sig_setjmp = dummyVar;
fdelay_start_timer = dummyVar;
critical_start = dummyVar;
critical_end = dummyVar;
task_create = dummyVar;
task_delete  = dummyVar;
fifo_init = dummyVar;
fifo_read = dummyVar;
fifo_write = dummyVar;
ktc_start_scheduler = dummyVar;
}



let sdelay_init_str = "ktc_sdelay_init_free"
let start_timer_init_str   = "ktc_start_time_init_free"
let fdelay_init_str = "ktc_fdelay_init_free"
let timer_create_str  = "ktc_timer_init_free"
let sig_setjmp_str = "setjmp" 
let fdelay_start_timer_str = "ktc_fdelay_start_timer_free" 
let critical_start_str  = "vTaskEnterCritical"
let critical_end_str = "vTaskExitCritical"
let task_create_str = "xTaskGenericCreate" 
let task_delete_str = "vTaskDelete"
let fifo_init_str = "ktc_fifo_init"
let fifo_read_str =  "ktc_fifo_read"
let fifo_write_str = "ktc_fifo_write"
let ktc_start_scheduler_str = "ktc_start_scheduler"


let sdelay_function_names = [
  sdelay_init_str;
  start_timer_init_str;
  fdelay_init_str;
  timer_create_str;
  sig_setjmp_str;
  fdelay_start_timer_str;
  critical_start_str;
  critical_end_str;
  task_create_str;
  task_delete_str;
  fifo_init_str;
  fifo_read_str;
  fifo_write_str;
  ktc_start_scheduler_str;

]


let findGlobalFifo (f : file)  =
  let glist = List.find_all (fun gi -> match gi with
			|GVar(vi, _, _) when  (isFifoType vi.vtype)  -> true
			|_ ->  false ) f.globals  in
  let vchan = List.map (fun gv -> match gv with
			|GVar(vi, _, _) -> vi.vname
			|_ -> E.s (E.bug "List must only contain global variable declaration\n"); "error"
	     ) glist   in
  vchan


let findGlobalFifoVar (f : file) str  =
  let glist = List.find_all (fun gi -> match gi with
			|GVar(vi, _, _) when  (vi.vname = str)  -> true
			|_ ->  false ) f.globals  in
  let vchan = List.map (fun gv -> match gv with
			|GVar(vi, _, _) -> vi
			|_ -> E.s (E.bug "List must only contain global variable declaration\n")
	     ) glist   in
		(List.hd vchan)
	

let findGlobalLvc (f : file)  =
  let glist = List.find_all (fun gi -> match gi with 
			|GVar(vi, _, _) when  (isLVType vi.vtype)  -> true
			|_ ->  false ) f.globals  in
  let vchan = List.map (fun gv -> match gv with
			|GVar(vi, _, _) -> vi.vname 
			|_ -> E.s (E.bug "List must only contain global variable declaration\n"); "error"
	     ) glist   in 
   vchan

let isSdelayFun (name : string) : bool = L.mem name sdelay_function_names

let initSdelayFunctions (f : file)  : unit =
  let focf : string -> typ -> varinfo = findOrCreateFunc f in
  let init_type = TFun(intType, Some["unit", charPtrType, [];],
		     false, []) in
  let end_type = TFun(intType, Some["intrval", intType, [];],
		     false, []) in
  let void_type = TFun(intType, None,
		     false, []) in
  sdelayfuns.sdelay_init <- focf sdelay_init_str init_type;
  sdelayfuns.start_timer_init <- focf start_timer_init_str   end_type;
  sdelayfuns.fdelay_init <- focf fdelay_init_str init_type;
  sdelayfuns.timer_create <- focf timer_create_str init_type;
  sdelayfuns.sig_setjmp <- focf   sig_setjmp_str init_type;
  sdelayfuns.fdelay_start_timer <- focf  fdelay_start_timer_str init_type;
  sdelayfuns.critical_start <- focf critical_start_str init_type;
  sdelayfuns.critical_end <- focf critical_end_str init_type;
  sdelayfuns.task_create <- focf task_create_str init_type;
  sdelayfuns.task_delete <- focf task_delete_str init_type;
  sdelayfuns.fifo_init <- focf fifo_init_str init_type;
  sdelayfuns.fifo_read <- focf fifo_read_str init_type;
  sdelayfuns.ktc_start_scheduler <- focf ktc_start_scheduler_str void_type;
  sdelayfuns.fifo_write <- focf fifo_write_str init_type

  

let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) (lv :lval option)  =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s, t_id = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)), (List.hd (List.rev argL))  in
  [Call(lv,v2e sdelayfuns.sdelay_init, [intervl;tunit;s;t_id;], loc)]

let makeSdelayEndInstr (structvar : varinfo) (timervar : varinfo) (tp : varinfo) (jmpvar : varinfo) (fname : string) =
  let s =  mkAddrOf((var structvar)) in
  let start_time_init = Call(None, v2e sdelayfuns.start_timer_init, [s;], locUnknown) in 
  let timerlvl = ((var timervar)) in
  let timername = fname^"_timer" in 
  let offtname = match jmpvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "tname", NoOffset) in	
  let sttname = (Var jmpvar, offtname) in
  let setInst = Set((sttname), (mkString timername), locUnknown) in
  let timer_init = Call(Some timerlvl, v2e sdelayfuns.timer_create, [(mkAddrOf(var jmpvar));], locUnknown) in
  [mkStmtOneInstr setInst; mkStmtOneInstr start_time_init; mkStmtOneInstr timer_init]

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) (timervar :varinfo) (lv : lval option) (ret_jmp : varinfo) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s, t_id = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)), (List.hd(List.rev argL)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;(v2e timervar); (v2e ret_jmp); t_id;], loc)]


let makeCriticalStartInstr (loc: location) = 
  i2s	(Call(None, v2e sdelayfuns.critical_start, [], loc) )

let makeCriticalEndInstr (loc: location)=
  i2s ( Call(None, v2e sdelayfuns.critical_end, [], loc) )

let makeTaskCreateInstr (handlevar : varinfo) (funvar : varinfo) (idlePrioVar : varinfo) (loc:location) arg= 
  let addrHandle = mkAddrOf(var handlevar) in
  let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in 
	(*let addrFun = mkAddrOf(var funvar) in
	i2s ( Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero; addrFun; Cil.zero;], loc)) *)
  Call(None, v2e sdelayfuns.task_create, [v2e funvar; (mkString (funvar.vname^handlevar.vname)); (integer 1024); arg; v2e idlePrioVar; addrHandle; nullptr; nullptr ], loc)

let makeTaskCreateInstrVarExp (handlevar : varinfo) (funvar : varinfo) (prioVar : exp) (loc:location) argList =
  let arg = (match argList with 
             | [] -> (Cil.mkCast Cil.zero Cil.voidPtrType) 
             | h::rest -> h ) in 
  let addrHandle = mkAddrOf(var handlevar) in
  let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in 
	(*let addrFun = mkAddrOf(var funvar) in
	i2s ( Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero; addrFun; Cil.zero;], loc)) *)
  Call(None, v2e sdelayfuns.task_create, [v2e funvar; (mkString (funvar.vname^handlevar.vname)); (integer 1024); arg ; prioVar; addrHandle; nullptr; nullptr ], loc)

let makeTaskDeleteInstr (handlevar : varinfo)  =
  let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in
  let handlelv = v2e handlevar in
  let compExp = BinOp(Ne, handlelv, nullptr, Cil.voidPtrType) in
  let stm = i2s ( Call(None, v2e sdelayfuns.task_delete, [v2e handlevar;], locUnknown)) in 
  let blk_if = mkBlock [stm] in
  let blk_else = mkBlock[] in
  let ifStmt = If(compExp, blk_if, blk_else, locUnknown) in
  mkStmt ifStmt

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
			|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "sdelay")  -> vi.vid
			|_ -> E.s(E.bug "Error: label"); -1

let get_label_no i =
	match i with
	|Call(_,Lval(Var vf,_),argList,_) -> E.log "%s\n" vf.vname; List.hd (List.rev argList)

let getInstruction s =
	match s.skind with
	| Instr il -> List.hd il 
	

let findgoto data s =
	(*let id = getvaridStmt s in  *)
	let tpinstr = getInstruction s in 
	let id = get_label_no tpinstr in 
	 try HT.find data id
		with Not_found -> E.s(E.bug "goto not found")

let maketimerfdelayStmt structvar argL timervar retjmp firmStmt jmpvar =
	let i = Cil.one in
	let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in 
	let intr, tunit, timr, s = L.hd argL, time_unit, v2e timervar, v2e structvar in
	let offset' = match jmpvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "envn", NoOffset) in	
	let buf = Lval (Var jmpvar, offset') in
	let sigInt = Call(Some(var retjmp), v2e sdelayfuns.sig_setjmp, [buf], locUnknown) in
	let letjmpto = findgoto labelHash firmStmt in 
	(*let goto_label = dummyStmt in *)
	let goto_label = mkStmt (Goto(ref letjmpto, locUnknown))  in 
	let ifBlock = ifBlockFunc goto_label retjmp  in
	let startTimer = Call(None, v2e sdelayfuns.fdelay_start_timer, [intr; tunit;timr;s;], locUnknown) in
	  [mkStmtOneInstr sigInt; ifBlock; mkStmtOneInstr startTimer ]

let instrVarInfoIfFun il =
		match (List.hd il) with 
		|Call(_,Lval(Var vi, _), _, _) -> vi
		|_ -> E.s (E.log "Not function")


let unrollStmtIfInstr s =
	match s.skind with
	|Instr il ->  il
	|_ -> E.s (E.log "Not instruction")

 
let taskDeleteList slist start_sched  =
	let revList = List.rev slist in
	let ret_stmt  = List.hd revList in
	let revList = List.tl revList in
	let taskdelete_stmt = List.map makeTaskDeleteInstr !all_handles in
	let revList = List.append taskdelete_stmt (List.append start_sched revList) in
	let revList = List.append [ret_stmt] (revList) in
		List.rev revList 
	 
let addTaskDelete slist start_sched =
	if List.length !all_handles = 0 then slist
	else  taskDeleteList slist start_sched
 
let instrTimingPoint (i : instr) : bool = 
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "fdelay") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "sdelay")  -> true
    | _ -> false

let instrTimingPointAftr (i : instr) : bool =
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "ktc_sdelay_init_free") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "ktc_fdelay_init_free")  -> true
    | _ -> false
(*
let getFirmInterval s =
	match s.kind with
	|Instr il when List.hd il = Call (_, Lval (Var vf, _), argList, _) -> argList
*)

(* START - The below functions are responsible for making a timing point as a standalone statement *)
 
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
(*END - timing_point *)

(*
let printAllTask =
	E.log "All tasks :::: ";
	List.iter (fun (a,b) ->  (E.log "(%s, %d)" a b) ) !all_task; ()
*)




let isFifo varnme fifoq =
	if(List.exists (fun x -> x = varnme) fifoq) then true else false


let isFunTaskName vname =
	List.exists (fun a  -> if (fst a) = vname then true else false ) !all_task

let isFunTask vi =
	List.exists (fun a  -> if (fst a) = vi.vname then true else false ) !all_task

let isTaskPartOfInstr il  = 
	match il with 
	|Call(_,Lval(Var vi,_),_,_) when (isFunTask vi) ->  E.s (E.error "Undecidable number of tasks %a" dn_instr il) ; () 
	|_ -> ()

let isTaskPartOfStmt s =
	match s.skind with 
	|Instr il -> List.iter isTaskPartOfInstr il ; ()
	|_ -> ()

let findTasks fglobal = 
	match fglobal with
	| GFun(f, _) ->  (
		match f.svar.vtype with
			| TFun(rt,_,_,attr) when (isTaskType rt)->
				all_task := (f.svar.vname, 0) :: !all_task; ()
			| _ -> ()
	)
	| _ -> ()

(* lvchannel commenting out*)
(*

let  rec findTasksCallingFuncWriter fname cgraph =
	let cg_node: CG.callnode =
	    try H.find cgraph fname
	    with Not_found -> E.s (E.bug "Cannot find call graph info for %s"
				     fname) in
	let callerHash = cg_node.CG.cnCallers in
	let hashToList = Inthash.fold (fun k v acc ->  v :: acc) callerHash [] in
	if (List.for_all (fun a -> (isFunTaskName (CG.nodeName (a.CG.cnInfo)))) hashToList) then
			let stringNode = ((List.map (fun a -> (CG.nodeName (a.CG.cnInfo)))) hashToList) in
			all_write := List.append stringNode !all_write;
	else
			let nodeofTask = List.filter (fun a -> (isFunTaskName (CG.nodeName (a.CG.cnInfo)))) hashToList in
			let stringNodeofTask = ((List.map (fun a -> (CG.nodeName (a.CG.cnInfo)))) nodeofTask) in
			all_write := List.append stringNodeofTask !all_write;
			let notTask = (List.filter (fun a -> (not(isFunTaskName (CG.nodeName (a.CG.cnInfo))))) hashToList) in
			let stringNotTask = (List.map (fun a -> (CG.nodeName (a.CG.cnInfo)))) notTask in
			List.iter (fun a -> findTasksCallingFuncWriter a cgraph ) stringNotTask

let  rec findTasksCallingFuncReader fname cgraph =
	let cg_node: CG.callnode = 
	    try H.find cgraph fname
	    with Not_found -> E.s (E.bug "Cannot find call graph info for %s"
				     fname) in
	let callerHash = cg_node.CG.cnCallers in
	let hashToList = Inthash.fold (fun k v acc ->  v :: acc) callerHash [] in 
	if (List.for_all (fun a -> (isFunTaskName (CG.nodeName (a.CG.cnInfo)))) hashToList) then
			let stringNode = ((List.map (fun a -> (CG.nodeName (a.CG.cnInfo)))) hashToList) in 
			all_read := List.append stringNode !all_read; 
	else
			let nodeofTask = List.filter (fun a -> (isFunTaskName (CG.nodeName (a.CG.cnInfo)))) hashToList in
			let stringNodeofTask = ((List.map (fun a -> (CG.nodeName (a.CG.cnInfo)))) nodeofTask) in
			all_read := List.append stringNodeofTask !all_read; 
			let notTask = (List.filter (fun a -> (not(isFunTaskName (CG.nodeName (a.CG.cnInfo))))) hashToList) in
			let stringNotTask = (List.map (fun a -> (CG.nodeName (a.CG.cnInfo)))) notTask in 

			List.iter (fun a -> findTasksCallingFuncReader a cgraph ) stringNotTask    

let findNumReadersPerTask b =
	let elm = List.find (fun a -> if (fst a) = b then true else false) !all_task in
	snd elm

let numberRW readers=
	let reader_list = List.map (fun a -> findNumReadersPerTask a) readers in
	let totalReader = List.fold_left (fun a b -> a + b) 0 reader_list in
	totalReader
 *)

let getInstr s =
	match s.skind with
	|Instr il when il <> []-> match List.hd il with 
			|Call(_,Lval(Var vi,_),argList,loc)  -> argList 

let getExpNameR e = 
	match e with
	|BinOp(_, SizeOfStr s1, e1, _) -> (s1, e1)
	(*|BinOp(_, Const(CStr c1), Const(CStr c2), _) -> (c1, c2) *)
	| _ -> E.s (E.bug "Wrong format of read block") ; ("e", Cil.zero)

let getExpNameW e =
	match e with
	|BinOp(_, SizeOfStr s1, e1, _) -> (s1, e1)
	(*|BinOp(_, Const(CStr c1), Const(CStr c2), _) -> (c1, c2) *)
	| _ -> E.s (E.bug "Wrong format of write block"); ("error", Cil.zero)
(*

 let replaceBlockWithFdelay s tl b data structvar tpstructvar timervar ret_jmp data sigvar =
		match s.skind with 
		|Instr il when il <> [] ->  
			 begin 
			 if instrTimingPointAftr (List.hd il) && (checkFirmSuccs data s) then
			 (*let label_stmt = mkStmt (Instr []) in
			 label_stmt.labels <- [Label(string_to_int s.sid,locUnknown,false)] ;*)
			  (*let tname = E.log "out here fdelay" in*)
			 let firmSuccInst = retFirmSucc s data in
			 let intr = getInstr firmSuccInst in
			 let addthisTo = maketimerfdelayStmt structvar intr tpstructvar timervar ret_jmp firmSuccInst in
			 let changStmTo = (mkStmt s.skind)  :: addthisTo  in
			 let changStm = List.append changStmTo tl in 
			 b <-  mkBlock changStm 
			end ; b
				  
		 |_ -> b 
*)


	
class sdelayReportAdder filename fdec structvar jmpvar timervar ret_jmp data fname   = object(self)
 inherit nopCilVisitor

 method vinst (i :instr) =
	let sname = "fdelay" in
	let action [i] =
	match i with
	|Call(lv, Lval(Var vi,_),argList,loc) when (vi.vname = fname) -> makeSdelayInitInstr structvar argList loc lv
	|Call(lv, Lval(Var vi,_),argList,loc) when (vi.vname = sname) -> makeFdelayInitInstr structvar argList loc timervar lv ret_jmp
	(*|Call(_,LVal(Var vi,_),_,loc) when (vi.vname = "next") -> makeNextGoto loc *)
	|Call(_,Lval(Var vi,_),arg,_) when (isFunTask vi) -> let t1 = E.log "task 1" in
							let xhandleType = findType filename.globals "TaskHandle_t" in
							let t2 = E.log "task 2" in
							let xhandleVar = makeLocalVar fdec ("t_"^string_of_int(List.length !all_handles)) xhandleType in 
							let t3 = E.log "task 3" in
							let idleVar = findGlobalVar filename.globals "idle_prio" in
							let t4 = E.log "task 4" in
							let priovar = 5 - !fprio ; fprio := !fprio - 1 in
							let intr = makeTaskCreateInstrVarExp xhandleVar vi (integer !fprio) locUnknown arg in
							let t5 = E.log "task5" in
							all_handles := xhandleVar  :: (!all_handles); [intr]  

							(*let t1 = E.log "task 1" in
							let xhandleType = findType filename.globals "TaskHandle_t" in
							let t2 = E.log "task 2" in
							let xhandleVar = makeLocalVar fdec ("t_"^string_of_int(List.length !all_handles)) xhandleType in 
							let t3 = E.log "task 3" in
							let idleVar = findGlobalVar filename.globals "idle_prio" in
							let t4 = E.log "task 4" in
							let intr = makeTaskCreateInstr xhandleVar vi idleVar locUnknown arg in
							let t5 = E.log "task5" in
							all_handles := xhandleVar  :: (!all_handles); [intr]  *)
	(*|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "cread") -> all_read:= fdec.svar.vname ::  (!all_read); [i] *)
						   
	|_ -> [i]
	in
	ChangeDoChildrenPost([i], action) 
	(*
	
	method vblock b =
	if List.length b.bstmts <> 0 then  
	let action  b  =
	let s = List.hd if (List.tl b.bstmts) != [] then List in  (*this is the timing point*) 
	let tl  = (List.hd b.bstmts) in (*this is the label*)
	
	begin
	(*let replaceBlockWithFdelay (List.hd b.bstmts) (List.tl b.bstmts) b data structvar tpstructvar timervar ret_jmp data sigvar*)
	match s.skind with
	|Instr il when il <> [] -> 
		 if instrTimingPointAftr (List.hd il) && (checkFirmSuccs data s) then
		 (*let label_stmt = mkStmt (Instr []) in
		 label_stmt.labels <- [Label(string_to_int s.sid,locUnknown,false)] ;*)
		  (*let tname = E.log "out here fdelay" in*)
		 let firmSuccInst = retFirmSucc s data in
		 let intr = getInstr firmSuccInst in
		 let addthisTo = maketimerfdelayStmt structvar intr timervar ret_jmp firmSuccInst jmpvar in
		 let changStmTo = tl :: [mkStmt s.skind ] in
		 let changStm = List.append changStmTo addthisTo in 
		 (*let changStmTo = (mkStmt s.skind)  :: addthisTo  in
		 let changStm = List.append changStmTo tl in*)
		 b.bstmts <- changStm ; ()  
	 |_ -> () 
end;  b
(*in ChangeTo b*)
in ChangeDoChildrenPost(b, action) 
else
SkipChildren  *)


method vstmt s =
let action s =
match s.skind with
|Instr (il) when il <> []  -> E.log "start" ; begin 
	       if instrTimingPointAftr (List.hd il) && (checkFirmSuccs data s) then
	       let so = if (checkFirmSuccs data s) then E.log "true" else E.log "false"; Cil.zero in 
	       let firmSuccInst = retFirmSucc s data in
	       let s1 = E.log "s1" in 
	       let intr = getInstr firmSuccInst in
	       let s2 = E.log "s2" in
	       let addthisTo = maketimerfdelayStmt structvar intr timervar ret_jmp firmSuccInst jmpvar in
	       let s3 = E.log "s3" in
	       let changStm =  List.append  [mkStmtOneInstr (List.hd il)] addthisTo in
		 let s4 = E.log "s4" in
	       let nb = mkBlock changStm in
	       s.skind <- Block nb; ()
	       end; s
	       
|If(CastE(t,z),b,_,_) when isCriticalType t ->  begin 
						let cs_start =makeCriticalStartInstr (get_stmtLoc s.skind) in
						let cs_end = makeCriticalEndInstr (get_stmtLoc s.skind) in
						let nb = mkBlock[cs_start; mkStmt (Block b); cs_end] in
						s.skind <- Block nb; ()
						end; s

|If(CastE(t,z),b,_,_) when isNextType t ->      begin
						(*let blockStmt = retFirmSucc (List.hd b.bstmts) data  in*)
						let blockStmt = retTimingPointSucc (List.hd b.bstmts) data  in
						let letjmpto = findgoto labelHash blockStmt in
						let goto_label = mkStmt (Goto(ref letjmpto, locUnknown))  in
						let rtjmp =mkStmtOneInstr( Set((var ret_jmp), Cil.one, locUnknown)) in
						let nb = mkBlock[rtjmp; goto_label] in
						s.skind <- Block nb; ()
						end;E.log "next-end"; s(*
	|If(CastE(t,z),b,_,_) when isTaskType t -> begin
						let pthread_id_str = "pthread_t" in
						let pthread_id_type = findTypeinfo filename pthread_id_str in 
						let pthread_var = makeLocalVar fdec ("t_"^string_of_int(List.length !all_threads)) (TNamed(pthread_id_type, [])) in
						let instrList = unrollStmtIfInstr (List.hd b.bstmts) in
						let funvar = instrVarInfoIfFun instrList in
						let nb = mkBlock [makePthreadCreateInstr pthread_var funvar locUnknown] in
						all_threads:= pthread_var :: (!all_threads); s.skind <- Block nb; s
						 end *)

|_ -> s
in ChangeDoChildrenPost(s, action)





end
(*

class numRWAnalysis (fdec: fundec)  (f:file) (cgraph: CG.callgraph) (chanName : string) = object(self) 
	inherit nopCilVisitor
	
	method vstmt (s: stmt) =
	match s.skind with
	|If(CastE(t,e),b,_,_) when ((isReadType t) && ((fst (getExpNameR e)) = chanName)) ->   
										if (List.exists (fun a -> if (fst a) = fdec.svar.vname then true else false) !all_task) then 
										all_read := fdec.svar.vname :: !all_read 
										else findTasksCallingFuncReader fdec.svar.vname cgraph; DoChildren
	|If(CastE(t,e),b,_,_) when ((isWriteType t) && ((fst (getExpNameW e)) = chanName)) ->
										if (List.exists (fun a -> if (fst a) = fdec.svar.vname then true else false) !all_task) then
										all_write := fdec.svar.vname :: !all_write
										else findTasksCallingFuncWriter fdec.svar.vname cgraph; DoChildren 
	|_ -> DoChildren
end

class rwAnalysis f cgraph chanName = object(self)
	inherit nopCilVisitor 

	method vfunc (fdec : fundec) =
	let numRW = new numRWAnalysis fdec f cgraph chanName in
	visitCilBlock numRW fdec.sbody; DoChildren
end
*)
 
class concurrencyAnalysis f cgraph = object(self) 
	inherit nopCilVisitor 	

	method vstmt (s: stmt) =
	match s.skind with
	|Loop(b,_,_,_) -> List.iter isTaskPartOfStmt b.bstmts; DoChildren
	| _ -> DoChildren

	method vinst (i : instr) =
	match i with 
	|Call(_,Lval(Var vi,_),_,_) when (isFunTask vi) -> let cals =  List.map (fun (a, b) -> if (a = vi.vname) then (a, (b+1)) else (a,b)) !all_task in  
								all_task := []; 
								all_task := List.append cals !all_task; DoChildren
	|_ -> DoChildren


end
	
class addLabelStmt fdec = object(self)
	inherit nopCilVisitor

	method vinst (i :instr) = 
	let action [i] =
	match i with
	|Call(ret,lval,argList,loc) when (instrTimingPoint i)  ->   tp_id := !tp_id + 1;
								    let newargList = List.append argList [integer !tp_id] in
											[Call(ret,lval, newargList,loc)]
	|_ -> [i]
	 in
	ChangeDoChildrenPost([i], action)


	method vstmt (s :stmt) =
	let action s =
	match s.skind with 
	|Instr (il) ->  
			if (List.length il = 1 &&  instrTimingPoint (List.hd il)) && (instrTimingPoint (List.hd il)) then
			let label_name = "_"^string_of_int(s.sid) in
			let label_no =  (get_label_no (List.hd il) )in
			(*let label_no =  getvaridStmt s in*)
			let label_stmt = mkStmt (Instr []) in 
				label_stmt.labels <- [Label(label_name,locUnknown,false)]; E.log "s.sid  %d \n" s.sid; HT.add labelHash label_no label_stmt; 
			let changStmTo = List.append [label_stmt][mkStmt s.skind] in
			let block = mkBlock  changStmTo in
			s.skind <- Block block ;
			s
			else
			s

	|_ -> s
	in ChangeDoChildrenPost(s, action)
	(*
	method vinst (i :instr) = 
			if (instrTimingPoint (il))  then
			let label_name = "_"^string_of_int(s.sid) in
			let label_no =  s.sid in
			(*let label_no =  getvaridStmt s in*)
			let label_stmt = mkStmt (Instr []) in
				label_stmt.labels <- [Label(label_name,locUnknown,false)]; E.log "label : %d\n" label_no; IH.add labelHash label_no label_stmt;
			let changStmTo = List.append [mkStmt s.skind] [label_stmt] in
			let block = mkBlock  changStmTo in
			s.skind <- Block block ;
			s
			else
			s

	|_ -> s
	in ChangeDoChildrenPost(s, action)*)
end

let addLabel f =
	HT.clear labelHash; 
	let cVisitor = new addLabelStmt f in
	visitCilFile cVisitor f



class sdelayFunc filename fname = object(self)
	inherit nopCilVisitor

	method vfunc (fdec : fundec) =
		Cfg.clearFileCFG filename; Cfg.computeFileCFG filename; 
		Cfg.printCfgFilename (fdec.svar.vname ^ ".dot") fdec;
		 Cfg.clearFileCFG filename; all_handles := [];
	(*	Cfg.cfgFunPrint (fdec.svar.vname^".dot") fdec; 
		computeAvail fdec; 
		computeTPSucc fdec; 
		computeAvail  fdec; 
		let data = checkTPSucc fdec in *)
		let timername = "TimerHandle_t" in
		let ftimer =  findType filename.globals timername in 
		let ftimer = makeLocalVar fdec (fdec.svar.vname^"_timer") ftimer in             
		let tickname = "TickType_t" in
		let ci = findType filename.globals tickname in
		let timevar = makeLocalVar fdec "start_time" ci in
		let temptime = makeLocalVar fdec "temp_time" ci in 
		let jmpvartyp = findCompinfo filename "timer_env" in  
		let jmpvar  = makeLocalVar fdec ("env_"^fdec.svar.vname) (TComp(jmpvartyp, [])) in
		let ret_jmp = makeLocalVar fdec "retjmp" intType in
		let init_start = makeSdelayEndInstr timevar ftimer temptime jmpvar fdec.svar.vname  in
		let data =  checkTPSucc fdec filename  in 
		let y = checkAvailOfStmt fdec in
	(*	let addl = new  addLabelStmt filename in
		fdec.sbody <- visitCilBlock addl  fdec.sbody ; *)
		(*let y' = isErrorFree filename in*)
		let modifysdelay = new sdelayReportAdder filename fdec timevar jmpvar ftimer ret_jmp data fname  in
		(*E.log "passed this";*)
		let kk = E.log "Done" in
                let schedular_inst = Call(None, v2e sdelayfuns.ktc_start_scheduler, [], locUnknown)  in 
		fdec.sbody <- visitCilBlock modifysdelay fdec.sbody;  
		fdec.sbody.bstmts <- List.append init_start fdec.sbody.bstmts;	
                fdec.sbody.bstmts <- addTaskDelete fdec.sbody.bstmts [mkStmtOneInstr schedular_inst]; 
		ChangeTo(fdec)

end

(*again commenting out lvchanels*)
(*
class concurrencyImplmntSimpsonRead f fdec chanVarHash = object(self)
	inherit nopCilVisitor

	method vstmt (s: stmt) =
	let action s =  (*let action s = *)
	match s.skind with
	|If(CastE(t,e),b,_,_) when isReadType t -> let expName = getExpNameR e in
						   let pairVar = makeTempVar fdec ~name:("pair_"^(fst expName)) intType in
						   let indexVar = makeTempVar fdec ~name:("index_"^(fst expName)) intType in
						   let chanVar = HT.find chanVarHash (fst expName) in
						   let chanSet = HT.find simpsonChanSet (fst expName)  in
						   let ptrRead = makeTempVar fdec ~name:(snd expName) (TPtr((unrollType2dArray chanVar.vtype), [])) in
						   let ione = Set((var pairVar), (v2e (snd3 chanSet)), locUnknown) in
						   let itwo = Set((var (thd3 chanSet)), (v2e (pairVar)), locUnknown) in
						   let slotThree = (Var (fst3 chanSet), Index(v2e (pairVar), NoOffset)) in
						   let ithree = Set((var indexVar), (Lval slotThree), locUnknown) in
						   let readingIndex = (Var (chanVar), Index(v2e (pairVar), Index(v2e (indexVar), NoOffset)) ) in
						   let ifour = Set((var ptrRead), (mkAddrOf readingIndex), locUnknown) in
						   let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in
						   let iend = Set((var ptrRead), nullptr, locUnknown) in
						   let slist = [mkStmtOneInstr ione; mkStmtOneInstr itwo; mkStmtOneInstr ithree; mkStmtOneInstr ifour; mkStmt (Block b); mkStmtOneInstr iend] in
						   let nb = mkBlock slist in
						    s.skind <- Block nb; s
	 |If(CastE(t,e),b,_,_) when isWriteType t -> let expName = getExpNameW e in
						   let pairVar = makeTempVar fdec ~name:("pair_"^(fst expName)) intType in
						   let indexVar = makeTempVar fdec ~name:("index_"^(fst expName)) intType in
						   let chanVar = HT.find chanVarHash (fst expName) in
						   let chanSet = HT.find simpsonChanSet (fst expName)  in
						   let readingVar = snd3 chanSet in
						   let ptrWrite = snd expName in
						   let ione = Set((var pairVar), (UnOp(LNot, (v2e (thd3 chanSet)),readingVar.vtype)), locUnknown) in
						   let slotThree = (Var (fst3 chanSet), Index(v2e (pairVar), NoOffset)) in
						   let itwo = Set((var indexVar), (UnOp(LNot, (Lval slotThree), readingVar.vtype)), locUnknown) in
						   let writingIndex = (Var (chanVar), Index(v2e (pairVar), Index(v2e (indexVar), NoOffset)) ) in
						   let ithree = Set(writingIndex, ptrWrite , locUnknown) in
						   let ifour = Set(slotThree, v2e indexVar, locUnknown) in
						   let ifive = Set(var (snd3 chanSet), v2e pairVar, locUnknown) in
						   let slist = [mkStmtOneInstr ione; mkStmtOneInstr itwo; mkStmtOneInstr ithree; mkStmtOneInstr ifour; mkStmtOneInstr ifive; mkStmt (Block b) ] in
						   let nb = mkBlock slist in
						    s.skind <- Block nb; s
					
							
		 |_ -> s
		in ChangeDoChildrenPost(s, action)
	

end

class concurrencyImplmntSimpson f = object(self)
	inherit nopCilVisitor
	val mutable getChanVar = HT.create 34	

	method vvdec vi = 
	let cVar = if (isLVType vi.vtype)  then
			     let typSanAtt = typeRemoveAttributes [lv_str] vi.vtype in
			     let chanVar = makeGlobalVar ("data_"^vi.vname) (TArray(TArray(typSanAtt, Some(integer 2), []), Some(integer 2), [])) in
			      HT.add getChanVar vi.vname chanVar; chanVar
		   else vi
	in ChangeTo(cVar)
	(*
	method vglob (vg ) =
	let gVar = 
	match vg with 
	|GVar (vi, _, _ ) -> let cVar = if (isLVType vi.vtype)  then 
			     let typSanAtt = typeRemoveAttributes [lv_str] vi.vtype in 
			     let chanVar = makeGlobalVar ("data_"^vi.vname) (TArray(typSanAtt, Some(integer 4), [])) in
			     let slotVar = makeGlobalVar ("slot_"^vi.vname) (TArray(intType, Some(integer 2), [])) in
			     let latestVar = makeGlobalVar ("latest_"^vi.vname) intType in
			     let readingVar = makeGlobalVar ("reading_"^vi.vname) intType in 
			     let chanSet = (chanVar, slotVar, latestVar, readingVar) in 
			    (* HT.add getChanVar vi.vname chanSet; [GVar(chanVar, {init=None}, locUnknown);GVar(slotVar, {init=None}, locUnknown);
								  GVar(latestVar, {init=None}, locUnknown); GVar(readingVar, {init=None}, locUnknown)  ] *) [vg]
		   else [vg] in cVar
	|_ -> [vg]
	in ChangeTo(gVar)

	*)
	method vfunc fdec =
	
		let cread = new concurrencyImplmntSimpsonRead f fdec getChanVar in
		fdec.sbody <- visitCilBlock cread fdec.sbody ;
		ChangeTo(fdec) 

	

		
end
	
*)
let timing_basic_block f =
  let thisVisitor = new timingAnalysis f in
  (*visitCilFileSameGlobals thisVisitor f *) 
  visitCilFile thisVisitor f

let concurrencyA f =
	all_task := ("main", 1):: !all_task; List.iter findTasks f.globals; 
	let cgraph = CG.computeGraph f in 
	let vis = new concurrencyAnalysis f cgraph in
	visitCilFile vis f


let timingConstructsTransformatn f =
	 let fname = "sdelay" in
	let vis = new sdelayFunc f fname in
	visitCilFile vis f

(*
let concurrencyConstructsTransformatn f =
	(*if n = 1 then *)
	let cVis = new concurrencyImplmntSimpson f in
	visitCilFile cVis f 
	(*else 
	let cVis = new concurrencyImplmntCAB f in
	visitCilFile cVis f*)
*)

(*
let htcGlb f vname =
	let cabdsType = findCompinfo f "cab_ds" in
	let cbmType = findCompinfo f "cbm" in 
	let cabdsVar = makeGlobalVar ("cds"_^vname) (cabdsType)
	f.globals <- cabdsVar :: f.globals
*)

(*Only below commenting out lvchannels *)
(*
let simpsonGlb f vname  =
	let boolType = TInt(IBool, []) in
	let slotVar = makeGlobalVar ("slot_"^vname) (TArray(boolType, Some(integer 2), [])) in
	let latestVar = makeGlobalVar ("latest_"^vname) (boolType) in
	let readingVar = makeGlobalVar ("reading_"^vname) (boolType) in
	let init = makeZeroInit intType in
	let slotinit = CompoundInit(boolType, [(Index(Cil.zero, NoOffset), init); (Index(Cil.one, NoOffset), init)]) in
	let simpList = [(GVar(slotVar,{init=Some slotinit} , locUnknown)); (GVar(latestVar,{init=Some init}, locUnknown)); (GVar(readingVar,{init=Some init}, locUnknown))] in 
	let simpSet = (slotVar, latestVar, readingVar) in
	f.globals <- List.append simpList f.globals ;
	HT.add simpsonChanSet vname simpSet; ()

let rec addGlobalVarChan f lvcList =
	match lvcList with
	|c::res-> let reads = HT.find readChanHash c in
		    let num = numberRW reads in
		    if(num = 1) then (simpsonGlb f c)  else () ; (E.log "Number of readers for %s ---> %d\n" c num);  addGlobalVarChan f res
	|[] -> []

let rec checkWriteOperation f lvcList =
	match lvcList with
	|c::res-> let writes =  HT.find writeChanHash c in
		  let num = numberRW writes in 
		  (E.log "Number of writers for %s ---> %d\n" c num); 
		  if (num > 1) then (E.s (E.error "More than one writer tasks for channel %s" c)) else E.log "" ; checkWriteOperation f res
	|[] -> []
	
let rwInterfaceFunc f chanName cgraph=
	let emptyRW = [] in
	all_read := emptyRW;
	all_write := emptyRW; 	
	let rVis = new rwAnalysis f cgraph chanName in
		visitCilFile rVis f; () 


let rec rwTaskOfChan f cl cgraph=
	match cl with 
	|c::rest->  let g = rwInterfaceFunc f c cgraph in
		    let reads = !all_read in
		    let writes = !all_write in
		    let unique_read = remove_duplicates_in_list reads in
		    let unique_write = remove_duplicates_in_list writes in 
		    HT.add readChanHash c unique_read; HT.add writeChanHash c unique_write; rwTaskOfChan f rest cgraph   
	| [] -> []  

 
let chanReaderWriterAnalysis f = 
	let lvList = findGlobalLvc f in
	let cgraph = CG.computeGraph f in 
	rwTaskOfChan f lvList cgraph;
	checkWriteOperation f lvList;
	addGlobalVarChan f lvList; ()
	 *)


class fifoQu f fdec  = object(self)
	inherit nopCilVisitor
       (*saranya*)
	method vstmt (s: stmt) =
	let action s =  (*let action s = *)
	match s.skind with
	|If(CastE(t,e),b,_,_) when isInitType t -> if (isFifo (fst (getExpNameW e)) !fifovarlst) then
						   let fifovar = HT.find fifoChanSet (fst (getExpNameW e)) in
						   let init_call = Call(None, v2e sdelayfuns.fifo_init, [(mkAddrOf(var fifovar));], locUnknown) in
						   let slist = [mkStmtOneInstr init_call] in
						   let nb = mkBlock slist in
						    s.skind <- Block nb; E.log "INIT-END"; s
						   else
						   s
	|If(CastE(t,e),b,_,_) when isWriteType t -> if (isFifo (fst (getExpNameW e)) !fifovarlst) then
						    let fifovar = HT.find fifoChanSet (fst (getExpNameW e)) in
						   let writeVal = snd (getExpNameW e) in
						   let write_call = Call(None, v2e sdelayfuns.fifo_write, [((v2e fifovar)); writeVal;], locUnknown) in
						   let slist = [mkStmtOneInstr write_call] in
						   let nb = mkBlock slist in
						    s.skind <- Block nb;E.log "WRITE-END";  s
						   else
						   s
       |If(CastE(t,e),b,_,_) when isReadType t ->  if (isFifo (fst (getExpNameR e)) !fifovarlst) then
						   let expName = getExpNameR e in
						   let fifovar = HT.find fifoChanSet (fst (expName)) in
						   let test = E.log "%s" (fst (expName))   in
						   let readVar = snd expName in
						   (*let vl = begin match readVar with 
							  |LVal(var v,_) -> v
							  |_ -> E.log "error" end
						   let readVar = findLocalVar fdec.slocals (snd expName) in *)
						   let read_call = Call(None, v2e sdelayfuns.fifo_read, [((v2e fifovar)); readVar;], locUnknown) in
						   let slist = [mkStmtOneInstr read_call] in
						   let nb = mkBlock slist in
						    s.skind <- Block nb; E.log "READ-END"; s
						   else
						   s


	 |_ -> s
	  in ChangeDoChildrenPost(s, action)


end

class fifoTrans f = object(self)
		inherit nopCilVisitor
		method vfunc fdec =
		let fifo = new fifoQu f fdec  in
		fdec.sbody <- visitCilBlock fifo fdec.sbody;
		ChangeTo(fdec)
end


let fifoGlb f vname  =
(*	let fifoTypeInfo = findCompinfo f "QueueHandle_t" in
	let fifotyp = TComp((fifoTypeInfo), []) in *)
	let fifoTypeInfo = findTypeinfo f "QueueHandle_t" in
	let fifotyp = TNamed((fifoTypeInfo), []) in 
	let fifoVar = makeGlobalVar ("fifo"^vname) voidPtrType in
	(*let fifoVar = makeGlobalVar ("fifo"^vname) (TPtr(fifotyp, [])) in*)
	(*let fifoVar = makeGlobalVar ("cds_"^vname) fifotyp in *)
	let cvList  = [GVarDecl(fifoVar, locUnknown)] in
	f.globals <- List.append cvList f.globals;
	HT.add fifoChanSet vname fifoVar;
	fifovarlst := vname :: !fifovarlst; ()

let rec addGlobalFifoVar lst f =
  match lst with
  | c :: res -> fifoGlb f c ; addGlobalFifoVar res f
  | [] -> []



let fifoAnalysi f =
  let fifolist = findGlobalFifo f in addGlobalFifoVar fifolist f;


let cVis = new fifoTrans f in
   visitCilFile cVis f

 
let sdelay (f : file) : unit =
initSdelayFunctions f; timing_basic_block f; Cfg.computeFileCFG f; addLabel f; Cfg.clearFileCFG f; concurrencyA f; 
List.iter (fun (a,b) -> E.log "(%s %d)" a b) !all_task; fifoAnalysi f ; (*chanReaderWriterAnalysis f; *) 
timingConstructsTransformatn f; (*concurrencyConstructsTransformatn f ;*) () 



(*
let sdelay (f : file) : unit =
initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
let vis = new sdelayFunc f fname in
*) 
