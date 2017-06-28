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

let debug = ref false
let labelHash =  HT.create 64
let tp_id = ref 0
let all_task = ref []
let all_read = ref []
let all_write = ref[] 
let all_threads = ref []
let fifovarlst = ref [] 
let readChanHash = HT.create 34 
let writeChanHash = HT.create 34
let simpsonChanSet = HT.create 34 
let htcChanSet = HT.create 34
let fifoChanSet = HT.create 34
let signumb = ref 0


let critical_str = "critical"
let next_str = "next"
let task_str = "task"
let lv_str = "lvchannel"
let read_str = "read_block"
let write_str = "write_block"
let init_str = "init_block"
let fifo_str = "fifochannel"

let hasCriticalAttrs : attributes -> bool = hasAttribute critical_str
let isCriticalType (t : typ) : bool = t |> typeAttrs |> hasCriticalAttrs

let hasNextAttrs : attributes -> bool = hasAttribute next_str
let isNextType (t : typ) : bool = t |> typeAttrs |> hasNextAttrs

let hasTaskAttrs : attributes -> bool = hasAttribute task_str
let isTaskType (t : typ) : bool = t |> typeAttrs |> hasTaskAttrs

let hasLVAttrs : attributes -> bool = hasAttribute lv_str
let isLVType (t : typ) : bool = t |> typeAttrs |> hasLVAttrs

let hasFIFOAttrs : attributes -> bool = hasAttribute fifo_str
let isFifoType (t : typ) : bool = t |> typeAttrs |> hasFIFOAttrs


let hasReadAttrs : attributes -> bool = hasAttribute read_str
let isReadType (t : typ) : bool = t |> typeAttrs |> hasReadAttrs

let hasWriteAttrs : attributes -> bool = hasAttribute write_str
let isWriteType (t : typ) : bool = t |> typeAttrs |> hasWriteAttrs

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
  mutable pthread_create : varinfo;
  mutable pthread_join : varinfo;
  mutable htc_get : varinfo;
  mutable htc_unget : varinfo; 
  mutable htc_reserve : varinfo;
  mutable htc_putmes : varinfo;
  mutable fifo_init : varinfo;
  mutable fifo_read : varinfo;
  mutable fifo_write : varinfo;
  mutable simsp_equal : varinfo;
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
  pthread_create = dummyVar;
  pthread_join = dummyVar;
  htc_get = dummyVar;
  htc_unget = dummyVar;
  htc_reserve = dummyVar;
  htc_putmes = dummyVar;
  fifo_init = dummyVar;
  fifo_read = dummyVar;
  fifo_write = dummyVar;
  simsp_equal = dummyVar;
}



let sdelay_init_str = "ktc_sdelay_init"
let start_timer_init_str   = "ktc_start_time_init"
let fdelay_init_str = "ktc_fdelay_init"
let timer_create_str  = "ktc_create_timer"
let sig_setjmp_str = "__sigsetjmp" 
let fdelay_start_timer_str = "ktc_fdelay_start_timer" 
let critical_start_str  = "ktc_critical_start"
let critical_end_str = "ktc_critical_end"
let pthread_create_str = "pthread_create" 
let pthread_join_str = "pthread_join"
let htc_get_str = "ktc_htc_getmes"
let htc_unget_str = "ktc_htc_unget"
let htc_reserve_str = "ktc_htc_reserve"
let htc_putmes_str = "ktc_htc_putmes"
let fifo_init_str = "ktc_fifo_init"
let fifo_read_str =  "ktc_fifo_read"
let fifo_write_str = "ktc_fifo_write"
let  simsp_equal_str = "ktc_simpson"


let sdelay_function_names = [
  sdelay_init_str;
  start_timer_init_str;
  fdelay_init_str;
  timer_create_str;
  sig_setjmp_str;
  fdelay_start_timer_str;
  critical_start_str;
  critical_end_str;
  pthread_create_str;
  pthread_join_str;
  htc_get_str;
  htc_unget_str;
  htc_reserve_str;
  htc_putmes_str;
  fifo_init_str;
  fifo_read_str;
  fifo_write_str;
  simsp_equal_str;
]


let findGlobalLvc (f : file)  =
	let glist = List.find_all (fun gi -> match gi with 
				|GVar(vi, _, _) when  (isLVType vi.vtype)  -> true
				|_ ->  false ) f.globals  in
	let vchan = List.map (fun gv -> match gv with
				|GVar(vi, _, _) -> vi.vname 
				|_ -> E.s (E.bug "List must only contain global variable declaration\n"); "error"
		     ) glist   in 
			vchan

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
  sdelayfuns.fdelay_start_timer <- focf  fdelay_start_timer_str init_type;
  sdelayfuns.critical_start <- focf critical_start_str init_type;
  sdelayfuns.critical_end <- focf critical_end_str init_type;
  sdelayfuns.pthread_create <- focf pthread_create_str init_type;
  sdelayfuns.htc_get <- focf htc_get_str init_type;
  sdelayfuns.htc_unget <- focf htc_unget_str init_type;
  sdelayfuns.htc_reserve <- focf htc_reserve_str init_type;
  sdelayfuns.htc_putmes <- focf htc_putmes_str init_type;
  sdelayfuns.pthread_join <- focf pthread_join_str init_type;
  sdelayfuns.fifo_init <- focf fifo_init_str init_type;
  sdelayfuns.fifo_read <- focf fifo_read_str init_type;
  sdelayfuns.fifo_write <- focf fifo_write_str init_type;
  sdelayfuns.simsp_equal <- focf simsp_equal_str init_type
	
let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location)  =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s, t_id = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)), (List.hd (List.rev argL))  in
  [Call(None,v2e sdelayfuns.sdelay_init, [intervl;tunit;s;t_id;], loc)]

let makeSdelayEndInstr (structvar : varinfo) (timervar : varinfo) (tp : varinfo) (signo : int)=
  let s =  mkAddrOf((var structvar)) in
  let start_time_init = Call(None, v2e sdelayfuns.start_timer_init, [s;], locUnknown) in 
  let t =  mkAddrOf((var timervar)) in
  let handlrt = mkAddrOf((var tp)) in
  let timer_init = Call(None, v2e sdelayfuns.timer_create, [t;handlrt; (integer signo);], locUnknown) in
  [mkStmtOneInstr start_time_init; mkStmtOneInstr timer_init]

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) (retjmp) (signo) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s, t_id = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)), (List.hd(List.rev argL)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;t_id;(v2e retjmp); signo;], loc)]

let makeCriticalStartInstr (sigvar : varinfo) (loc: location) = 
	let argSig = mkAddrOf (var sigvar) in
	i2s	(Call(None, v2e sdelayfuns.critical_start, [argSig;], loc) )

let makeCriticalEndInstr (sigvar : varinfo) (loc: location)=
        let argSig = mkAddrOf (var sigvar) in
        i2s ( Call(None, v2e sdelayfuns.critical_end, [argSig;], loc) )

let makePthreadCreateInstr (threadvar : varinfo) (funvar : varinfo) (loc:location)= 
	let addrThread = mkAddrOf(var threadvar) in
	let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in
	(*let addrFun = mkAddrOf(var funvar) in
	i2s ( Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero; addrFun; Cil.zero;], loc)) *)
	Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero; v2e funvar; nullptr;], loc)

let makePthreadJoinInstr fdec (threadvar : varinfo)  =
	let threadvoidptr = makeLocalVar fdec (threadvar.vname^"_join") (voidPtrType) in
        i2s ( Call(None, v2e sdelayfuns.pthread_join, [v2e threadvar; (mkAddrOf (var threadvoidptr));], locUnknown))

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
       	|Call(_,Lval(Var vf,_),argList,_) -> (*E.log "%s\n" vf.vname;*) List.hd (List.rev argList)

let getInstruction s =
	match s.skind with
	| Instr il -> List.hd il 
	

let findgoto data s =
        (*let id = getvaridStmt s in  *)
	let tpinstr = getInstruction s in 
        let id = get_label_no tpinstr in 
         try HT.find data id
                with Not_found -> E.s(E.bug "not found")

let maketimerfdelayStmt structvar argL tpstructvar timervar retjmp firmStmt =
	 let offset' = match tpstructvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "env", NoOffset) in	
	let buf = Lval(Var tpstructvar, offset') in
	let i = Cil.one in
	let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in 
	let intr, tunit, timr, s = L.hd argL, time_unit, v2e timervar, v2e structvar in
	let sigInt = Call(Some(var retjmp), v2e sdelayfuns.sig_setjmp, [buf;i;], locUnknown) in
	let letjmpto = findgoto labelHash firmStmt in 
	(*let goto_label = dummyStmt in *)
	let goto_label = mkStmt (Goto(ref letjmpto, locUnknown))  in 
	let ifBlock = ifBlockFunc goto_label retjmp  in
	let st = mkAddrOf (var structvar) in
	let startTimer = Call(None, v2e sdelayfuns.fdelay_start_timer, [intr; tunit;timr;st;], locUnknown) in
	  [mkStmtOneInstr sigInt; ifBlock; mkStmtOneInstr startTimer ]

let instrVarInfoIfFun il =
	match (List.hd il) with 
	|Call(_,Lval(Var vi, _), _, _) -> vi
	|_ -> E.s (E.log "Not function")

let unrollStmtIfInstr s =
	match s.skind with
	|Instr il ->  il
	|_ -> E.s (E.log "Not instruction")

 
let pthreadJoinList fdec slist =
	let revList = List.rev slist in
	let ret_stmt  = List.hd revList in
	let revList = List.tl revList in
	let pthreadjoin_stmt = List.map (fun a -> makePthreadJoinInstr fdec a) !all_threads in
	let revList = List.append pthreadjoin_stmt revList in
	let revList = List.append [ret_stmt] revList in
		List.rev revList 
	 
let addPthreadJoin fdec slist =
	if List.length !all_threads = 0 then slist
	else  pthreadJoinList fdec slist 
 
let instrTimingPoint (i : instr) : bool = 
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "fdelay") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "sdelay")  -> true
    | _ -> false

let instrTimingPointAftr (i : instr) : bool =
  (*let p =  E.log "instrTimingPointAftr" in*)
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "ktc_sdelay_init") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "ktc_fdelay_init")  -> (*E.log "true-true-true";*) true
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

let numberReaders c = 
	let reads = HT.find readChanHash c in
        let num = numberRW reads in
		num

let isSimp c =
	let num = numberReaders c in
	let value = if (num = 1)  then true else false
	in	
	value

let isFifo varnme fifoq = 
	if(List.exists (fun x -> x = varnme) fifoq) then true else false 


let getInstr s =
	match s.skind with
	|Instr il when il <> []-> match List.hd il with 
			|Call(_,Lval(Var vi,_),argList,loc)  -> argList 



let getExpNameR e = 
        match e with
        |BinOp(_, SizeOfStr s1, e1, _) -> (s1, e1)
        (*|BinOp(_, Const(CStr c1), Const(CStr c2), _) -> (c1, c2) *)
        | _ -> E.s (E.bug "Wrong format of read block") ; ("e", Cil.zero)
(*let getExpNameR e = 
	match e with
	|BinOp(_, SizeOfStr s1, SizeOfStr s2, _) -> (s1, s2)
	(*|BinOp(_, Const(CStr c1), Const(CStr c2), _) -> (c1, c2) *)
	| _ -> E.s (E.bug "Wrong format of read block") ; ("e", "s")
*)
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

	
class sdelayReportAdder filename fdec structvar tpstructvar timervar (ret_jmp : varinfo) data fname sigvar  signo = object(self)
  inherit nopCilVisitor
	
       method vinst (i :instr) =
        let sname = "fdelay" in
        let action [i] =
        match i with
        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = fname) -> makeSdelayInitInstr structvar argList loc
        |Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = sname) -> makeFdelayInitInstr structvar argList loc ret_jmp (integer signo)
	(*|Call(_,LVal(Var vi,_),_,loc) when (vi.vname = "next") -> makeNextGoto loc *)
	|Call(_,Lval(Var vi,_),_,_) when (isFunTask vi) -> 
                                                        let pthread_id_str = "pthread_t" in
                                                        let pthread_id_type = findTypeinfo filename pthread_id_str in
                                                        let pthread_var = makeLocalVar fdec ("t_"^string_of_int(List.length !all_threads)) (TNamed(pthread_id_type, [])) in
                                                        let intr = makePthreadCreateInstr pthread_var vi locUnknown in
                                                        all_threads:= pthread_var :: (!all_threads); [intr]
	(*|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "cread") -> all_read:= fdec.svar.vname ::  (!all_read); [i] *)
                                                   
        |_ -> [i]
        in
        ChangeDoChildrenPost([i], action)
	
	
	method vblock b =
	if List.length b.bstmts <> 0 then  
	let action  b  =
	let tl = (List.tl b.bstmts) in
	let s  = (List.hd b.bstmts) in
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
                         let addthisTo = maketimerfdelayStmt structvar intr tpstructvar timervar ret_jmp firmSuccInst in
			 let changStmTo = mkStmt s.skind :: tl in
			 let changStm = List.append changStmTo addthisTo in 
                         (*let changStmTo = (mkStmt s.skind)  :: addthisTo  in
                         let changStm = List.append changStmTo tl in*)
			 b.bstmts <- changStm ; ()  
                 |_ -> () 
	end;  b
	(*in ChangeTo b*)
	in ChangeDoChildrenPost(b, action) 
	else
	SkipChildren 

	
	method vstmt s =
	let action s =
	match s.skind with
	|If(CastE(t,z),b,_,_) when isCriticalType t ->  begin 
							let cs_start = makeCriticalStartInstr sigvar (get_stmtLoc s.skind) in
							let cs_end = makeCriticalEndInstr sigvar (get_stmtLoc s.skind) in
							let nb = mkBlock[cs_start; mkStmt (Block b); cs_end] in
							s.skind <- Block nb; s
							end

	|If(CastE(t,z),b,_,_) when isNextType t ->      begin
							(*let blockStmt = retFirmSucc (List.hd b.bstmts) data  in*)
                                                        let blockStmt = retTimingPointSucc (List.hd b.bstmts) data  in 
                                                        let letjmpto = findgoto labelHash blockStmt in
							let rtjmp =mkStmtOneInstr( Set((var ret_jmp), Cil.one, locUnknown)) in
        						let goto_label = mkStmt (Goto(ref letjmpto, locUnknown))  in
							let nb = mkBlock[rtjmp;goto_label] in
                                                        s.skind <- Block nb; s
                                                        end
	(*|If(CastE(t,z),b,_,_) when isTaskType t -> begin
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
                		label_stmt.labels <- [Label(label_name,locUnknown,false)]; (*E.log "s.sid  %d \n" s.sid;*) HT.add labelHash label_no label_stmt; 
			let changStmTo = List.append [mkStmt s.skind] [label_stmt] in
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

let initializeCabDs f chanVar cname numbuf = 
	let cabDs = HT.find htcChanSet cname in
	let cabdsType = findCompinfo f "cab_ds" in
	let freel = (Var (cabDs), Field((getCompField cabdsType "free"), NoOffset)) in
	let mrbl = (Var (cabDs), Field((getCompField cabdsType "mrb"), NoOffset)) in
	let maxc = (Var (cabDs), Field((getCompField cabdsType "maxcbm"), NoOffset)) in
	let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in
	let freeinit = mkStmtOneInstr (Set(freel, v2e chanVar, locUnknown)) in	
	let mrbinit = mkStmtOneInstr (Set(mrbl, nullptr, locUnknown)) in
	let maxc = mkStmtOneInstr (Set(maxc, integer numbuf, locUnknown)) in
		[freeinit; mrbinit; maxc]


	
class sdelayFunc filename fname fno = object(self)
        inherit nopCilVisitor

        method vfunc (fdec : fundec) =
		Cfg.clearFileCFG filename; Cfg.computeFileCFG filename; 
   		Cfg.printCfgFilename (fdec.svar.vname ^ ".dot") fdec;
		 Cfg.clearFileCFG filename; all_threads := [];
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
		let sigtype = findTypeinfo filename "sigset_t" in 
		let org_sig  = makeLocalVar fdec "orig_mask" (TNamed(sigtype, [])) in
		let rt_jmp = makeLocalVar fdec "retjmp" intType in
		let signo = (signumb := !signumb + 1);  !signumb in 
		let init_start = makeSdelayEndInstr structvar ftimer tpstructvar signo in
		let data =  checkTPSucc fdec filename  in 
		let y = checkAvailOfStmt fdec in
	(*	let addl = new  addLabelStmt filename in
                fdec.sbody <- visitCilBlock addl  fdec.sbody ; *)
		(*let y' = isErrorFree filename in*)	
		let modifysdelay = new sdelayReportAdder filename fdec structvar tpstructvar ftimer rt_jmp data fname org_sig signo in
		fdec.sbody <- visitCilBlock modifysdelay fdec.sbody;  
		fdec.sbody.bstmts <- List.append init_start fdec.sbody.bstmts;
		fdec.sbody.bstmts <- addPthreadJoin fdec fdec.sbody.bstmts ; 
                ChangeTo(fdec)

end

	

class concurrencyImplmntSimpsonRead f fdec chanVarHash hchanVarHash = object(self)
        inherit nopCilVisitor

	method vstmt (s: stmt) =
	let action s =  (*let action s = *)
        match s.skind with
	|If(CastE(t,e),b,_,_) when isInitType t ->      if(isSimp (fst (getExpNameW e))) then
						   	let expName = (getExpNameW e) in
						   	let chanVar = HT.find chanVarHash (fst expName) in
						   	let itr1 = makeTempVar fdec ~name:("i_"^(fst expName)) intType in
                                                   	let itr2 = makeTempVar fdec ~name:("j_"^(fst expName)) intType in	
						   	let ptr = (Var (chanVar), Index(v2e (itr1), Index(v2e (itr2), NoOffset))) in
						   	let fIns = Set(ptr, (snd (getExpNameW e)), locUnknown) in
						   	let fStm = [mkStmtOneInstr fIns] in
						   	let f2 = mkForIncr itr2 Cil.zero (integer 2) Cil.one fStm in
						   	let f1 = mkForIncr itr1 Cil.zero (integer 2) Cil.one f2 in
						   	let nb = mkBlock f1 in
                                                    	s.skind <- Block nb; s
						   else
							(*let p =  E.log "hit here 11111"  in*)
							let expName = (getExpNameW e) in
                                                        let chanVar = HT.find hchanVarHash (fst expName) in
							let numbuf = ((numberReaders (fst expName))) in
                                                        let itr1 = makeTempVar fdec ~name:("i_"^(fst expName)) intType in
							let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in
							let nextIndex = BinOp(PlusA, (v2e itr1), Cil.one, intType) in 
							let ptr_next = (Var (chanVar), Index(nextIndex, NoOffset)) in
							let cbmTypeinfo = findCompinfo f "cbm" in
							let usefieldinfo = getCompField cbmTypeinfo "use" in 
							let usel = (Var (chanVar), Index(v2e (itr1), Field(usefieldinfo, NoOffset))) in
							let datal = (Var (chanVar), Index(v2e (itr1), Field((getCompField cbmTypeinfo "data"), NoOffset))) in
                                                        let nextl = (Var (chanVar), Index(v2e (itr1), Field((getCompField cbmTypeinfo "nextc"), NoOffset))) in
							(*let usel =(ptr, Field(usefieldinfo, NoOffset)) in
							let datal = (ptr, Field((getCompField cbmTypeinfo "data"), NoOffset)) in
							let nextl = (ptr, Field((getCompField cbmTypeinfo "nextc"), NoOffset)) in  *)
							let useinit = mkStmtOneInstr (Set(usel, Cil.zero, locUnknown)) in
							let datainit = mkStmtOneInstr (Set(datal, Cil.zero, locUnknown)) in
							let nextinit =  mkStmtOneInstr (Set(nextl, (mkAddrOf ptr_next), locUnknown)) in
							let ifexp = BinOp(Eq, (v2e itr1), (integer numbuf), intType) in
							let ifblk = mkBlock [(mkStmtOneInstr (Set(nextl, nullptr, locUnknown)))] in
							let nexc =  mkStmt (If (ifexp, ifblk, (mkBlock[]), locUnknown)) in
							let forSt = [useinit; datainit; nextinit; nexc] in    
							let f1 = mkForIncr itr1 Cil.zero (integer (numbuf+1)) Cil.one forSt in	  
							let cabInitStm = initializeCabDs f chanVar (fst expName) numbuf in
							let allStmtBlk = List.append f1 cabInitStm in
							let nb = mkBlock allStmtBlk in
                                                        s.skind <- Block nb; (*E.log "hit here";*) s	
        |If(CastE(t,e),b,_,_) when isReadType t -> (*E.log "SRI SRI"; *)if(isSimp (fst (getExpNameR e))) then 
						   let expName = getExpNameR e in
						   let pairVar = makeTempVar fdec ~name:("pair_"^(fst expName)) intType in
						   let indexVar = makeTempVar fdec ~name:("index_"^(fst expName)) intType in
						   let chanVar = HT.find chanVarHash (fst expName) in
						   let chanSet = HT.find simpsonChanSet (fst expName)  in
						   let ptrRead = snd expName in 
						   (*let ptrRead = getVarFromExp (snd expName) in
 						    let ptrRead = findLocalVar fdec.slocals (snd expName) in *)
						   (*let ptrRead = makeLocalVar fdec (snd expName) (TPtr((unrollType2dArray chanVar.vtype), [])) in
						   let ptrReadEx = (snd expName) in
						   let ptrRead = getVarFromExp ptrReadEx in *)
						   let ione = Set((var pairVar), (v2e (snd3 chanSet)), locUnknown) in
						   let itwo = Set((var (thd3 chanSet)), (v2e (pairVar)), locUnknown) in
						   let slotThree = (Var (fst3 chanSet), Index(v2e (pairVar), NoOffset)) in
						   let ithree = Set((var indexVar), (Lval slotThree), locUnknown) in
						   let readingIndex = (Var (chanVar), Index(v2e (pairVar), Index(v2e (indexVar), NoOffset)) ) in
						   let ifour = Call(None, v2e sdelayfuns.simsp_equal, [(mkAddrOf readingIndex); ptrRead;], locUnknown) in
						   let slist = [mkStmtOneInstr ione; mkStmtOneInstr itwo; mkStmtOneInstr ithree; mkStmtOneInstr ifour; mkStmt (Block b)] in
						   let nb = mkBlock slist in
                                                    s.skind <- Block nb; (*E.log "GURUJI" *); s
						   else
                                                   let expName = getExpNameR e in
						   let chanVar = HT.find hchanVarHash (fst expName) in
                                                   let cabds = HT.find htcChanSet (fst expName)  in
						   let cbmTypeinfo = findCompinfo f "cbm" in
                                		   let cbmTyp = TComp((cbmTypeinfo), []) in
						   let ptrRead = getVarFromExp (snd expName) in 
						   (*let ptrRead = findLocalVar fdec.slocals (snd expName) in *)
					
						   let ptrBuf = makeTempVar fdec ~name:(ptrRead.vname) (TPtr(cbmTyp, [])) in  
						   (*let ptrReadEx = (snd expName)  in
						   let ptrRead = getVarFromExp ptrReadEx in *)
						   let getCall = Call((Some (var ptrBuf)),v2e sdelayfuns.htc_get, [(mkAddrOf (var cabds));], locUnknown) in
						   let usefieldinfo = getCompField cbmTypeinfo "use" in
						   let datal = (Mem (v2e ptrBuf), Field((getCompField cbmTypeinfo "data"), NoOffset)) in 
						   let iset = Set((var ptrRead), Lval datal, locUnknown) in
						   let ungetInstr = Call(None, v2e sdelayfuns.htc_unget, [(mkAddrOf (var cabds)); (v2e ptrBuf);], locUnknown) in 
						   let slist = [mkStmtOneInstr getCall; mkStmtOneInstr iset;  mkStmt (Block b); mkStmtOneInstr ungetInstr] in
						   let nb = mkBlock slist in
                                                    s.skind <- Block nb; s

	 |If(CastE(t,e),b,_,_) when isWriteType t -> if(isSimp (fst (getExpNameW e))) then 
						   let expName = getExpNameW e in
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
						   else
						   let expName = getExpNameW e in
                                                   let chanVar = HT.find hchanVarHash (fst expName) in
						   let cabds = HT.find htcChanSet (fst expName)  in
						   let cbmTypeinfo = findCompinfo f "cbm" in
                                                   let cbmTyp = TComp((cbmTypeinfo), []) in
                                                   let ptrRead = snd expName in
                                                   let ptrBuf = makeTempVar fdec ~name:("writmes"^(fst expName)) (TPtr(cbmTyp, [])) in
						   let rescall = Call(Some (var ptrBuf), v2e sdelayfuns.htc_reserve, [(mkAddrOf (var cabds));], locUnknown) in
						   let datal = (Mem (v2e ptrBuf), Field((getCompField cbmTypeinfo "data"), NoOffset)) in
						   let writemes = Set(datal, ptrRead, locUnknown) in 
						   let putmescall = Call(None, v2e sdelayfuns.htc_putmes, [(mkAddrOf (var cabds)); (v2e ptrBuf);], locUnknown) in
						   let slist = [mkStmtOneInstr rescall; mkStmtOneInstr writemes;  mkStmtOneInstr putmescall; mkStmt (Block b)] in
						   let nb = mkBlock slist in
						   s.skind <- Block nb; s
							
                |_ -> s
		in ChangeDoChildrenPost(s, action)
	

end

class concurrencyImplmntSimpson f = object(self)
        inherit nopCilVisitor
	val mutable getChanVar = HT.create 34	
	val mutable getHtcChanVar = HT.create 34
        method vvdec vi = 
        let cVar = if (isLVType vi.vtype)  then
			let cv =
			    if (not (isSimp vi.vname)) then
				let typSanAtt = typeRemoveAttributes [lv_str] vi.vtype in
				let cbmTypeinfo = findCompinfo f "cbm" in 
				let cbmTyp = TComp((cbmTypeinfo), []) in
				let numbuf = ((numberReaders vi.vname) + 1) in 
				let cbmArray = makeGlobalVar ("data_"^vi.vname) (TArray(cbmTyp, Some(integer numbuf), [])) in
				HT.add getHtcChanVar vi.vname cbmArray; (*E.log "ttt -> %s\n" vi.vname;*) cbmArray
			    else 
                             	let typSanAtt = typeRemoveAttributes [lv_str] vi.vtype in
                             	let chanVar = makeGlobalVar ("data_"^vi.vname) (TArray(TArray(typSanAtt, Some(integer 2), []), Some(integer 2), [])) in
                              	HT.add getChanVar vi.vname chanVar; chanVar in
				cv
                   else vi;
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
	
		let cread = new concurrencyImplmntSimpsonRead f fdec getChanVar getHtcChanVar in
		fdec.sbody <- visitCilBlock cread fdec.sbody;
		ChangeTo(fdec) 

	
		
end





class fifoQu f fdec  = object(self)
        inherit nopCilVisitor
       (*saranya*)
        method vstmt (s: stmt) =
        let action s =  (*let action s = *)
        match s.skind with
        |If(CastE(t,e),b,_,_) when isInitType t -> (*E.log "init";*)if (isFifo (fst (getExpNameW e)) !fifovarlst) then 
						   let fifovar = HT.find fifoChanSet (fst (getExpNameW e)) in 
						   let init_call = Call(None, v2e sdelayfuns.fifo_init, [((mkAddrOf (var fifovar)));], locUnknown) in
						   let slist = [mkStmtOneInstr init_call] in 
						   let nb = mkBlock slist in
                                                    s.skind <- Block nb; s
						   else 
					           s 
        |If(CastE(t,e),b,_,_) when isWriteType t ->(*E.log "WRITES";*)if (isFifo (fst (getExpNameW e)) !fifovarlst) then
                                                    let fifovar = HT.find fifoChanSet (fst (getExpNameW e)) in
						   let writeVal = snd (getExpNameW e) in 
                                                   let write_call = Call(None, v2e sdelayfuns.fifo_write, [((mkAddrOf (var fifovar))); writeVal;], locUnknown) in
                                                   let slist = [mkStmtOneInstr write_call] in
                                                   let nb = mkBlock slist in
                                                    s.skind <- Block nb; s
                                                   else
                                                   s 
       |If(CastE(t,e),b,_,_) when isReadType t -> (*E.log "READ";*)if (isFifo (fst (getExpNameR e)) !fifovarlst) then
						   let expName = getExpNameR e in
                                                   let fifovar = HT.find fifoChanSet (fst (expName)) in
                                                   let test = E.log "%s" (fst (expName))   in
						   let readVar = snd expName in
						   (*let vl = begin match readVar with 
							  |LVal(var v,_) -> v
							  |_ -> E.log "error" end
						   let readVar = findLocalVar fdec.slocals (snd expName) in *)
                                                   let read_call = Call(None, v2e sdelayfuns.fifo_read, [((mkAddrOf (var fifovar))); readVar;], locUnknown) in
						   let slist = [mkStmtOneInstr read_call] in
                                                   let nb = mkBlock slist in
                                                    s.skind <- Block nb; (*E.log "END";*) s
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
        let vis = new sdelayFunc f fname 0 in
        visitCilFile vis f

let concurrencyConstructsTransformatn f =
	(*if n = 1 then *)
	let cVis = new concurrencyImplmntSimpson f in
	visitCilFile cVis f 
	(*else 
	ldd simpsonChanSet vname simpSet; ()et cVis = new concurrencyImplmntCAB f in
        visitCilFile cVis f*)

let htcGlb f vname = 
        let cabdsTypeInfo = findCompinfo f "cab_ds" in
        let cabstyp = TComp((cabdsTypeInfo), []) in
        let cabdsVar = makeGlobalVar ("cds_"^vname) cabstyp in
        (*let cabdsVar = makeGlobalVar ("cds_"^vname) (TPtr(cabstyp, [])) in*)
        let cvList  = [GVarDecl(cabdsVar, locUnknown)] in
        f.globals <- List.append cvList f.globals; ()
 
let fifoGlb f vname  =
        let fifoTypeInfo = findCompinfo f "fifolist" in
	let fifotyp = TComp((fifoTypeInfo), []) in
        let fifoVar = makeGlobalVar ("fifo"^vname) (TPtr(fifotyp, [])) in
        (*let fifoVar = makeGlobalVar ("cds_"^vname) fifotyp in *)
	let cvList  = [GVarDecl(fifoVar, locUnknown)] in
        f.globals <- List.append cvList f.globals; 
	HT.add fifoChanSet vname fifoVar; 
	fifovarlst := vname :: !fifovarlst; ()

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

let rec addGlobalFifoVar lst f =
        match lst with
        | c :: res -> fifoGlb f c ; addGlobalFifoVar res f
        | [] -> []

let rec addGlobalVarChan f lvcList =
	match lvcList with
	|c::res-> let reads = HT.find readChanHash c in
		    let num = numberRW reads in
		    if(num = 1) then (simpsonGlb f c)  else htcGlb f c ; (*(E.log "Number of readers for %s ---> %d\n" c num);*)  addGlobalVarChan f res
	|[] -> []

let rec checkWriteOperation f lvcList =
        match lvcList with
        |c::res-> let writes =  HT.find writeChanHash c in
                  let num = numberRW writes in 
		  (*(E.log "Number of writers for %s ---> %d\n" c num);*) 
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
	(*E.log "RWA\n";*)
	let lvList = findGlobalLvc f in
	let cgraph = CG.computeGraph f in 
	rwTaskOfChan f lvList cgraph;
	checkWriteOperation f lvList;
	addGlobalVarChan f lvList;  ()
	 

let fifoAnalysi f =
	(*E.log "FIFO\n";*) 
	let fifolist = findGlobalFifo f in
        addGlobalFifoVar fifolist f;
	let cVis = new fifoTrans f in
        visitCilFile cVis f	
	 
let sdelay (f : file) : unit =
initSdelayFunctions f; timing_basic_block f; Cfg.computeFileCFG f; addLabel f; Cfg.clearFileCFG f; concurrencyA f; 
List.iter (fun (a,b) -> E.log "(%s %d)" a b) !all_task; fifoAnalysi f; chanReaderWriterAnalysis f; 
	timingConstructsTransformatn f; concurrencyConstructsTransformatn f ; () 



(*
let sdelay (f : file) : unit =
  initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
 *) 

