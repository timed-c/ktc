open Cil
open Pretty
open Ktcutil
open Yojson.Safe
open Csv

module E = Errormsg
module L = List
module H = Hashtbl

module IH = Inthash
module HT = Hashtbl
module DF = Dataflow
module AV = Avail
module CG = Callgraph


exception Eson of string

type edge_info =
{
  src : string;
  bcet : string;
  wcet : string;
  jitter : string;
  abort : string;
  dst : string;
}


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
let policyindex = ref 1
let lstinstpolicy = ref []
let jnodeslist = ref []
let jtasklist = ref []
let csvlist = ref []
let joblist = ref []
let abortlist = ref []
let offsetvar = ref 0
let offsetlist = ref []


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
  mutable gettime : varinfo;
  mutable timer_create : varinfo;
  mutable sig_setjmp : varinfo;
  mutable fdelay_start_timer : varinfo;
  mutable critical_start : varinfo;
  mutable critical_end : varinfo;
  mutable pthread_create : varinfo;
  mutable pthread_join : varinfo;
  mutable log_trace_execution : varinfo;
  mutable log_trace_release : varinfo;
  mutable log_trace_arrival : varinfo;
  mutable log_trace_init : varinfo;
  mutable log_get_time : varinfo;
  mutable log_trace_init_task : varinfo;
  mutable log_trace_previous_id : varinfo;
  mutable htc_get : varinfo;
  mutable htc_unget : varinfo;
  mutable htc_reserve : varinfo;
  mutable htc_putmes : varinfo;
  mutable fifo_init : varinfo;
  mutable fifo_read : varinfo;
  mutable fifo_write : varinfo;
  mutable simsp_equal : varinfo;
  mutable spolicy_set : varinfo;
  mutable compute_priority : varinfo;
  mutable nelem : varinfo;
  mutable blocksignal : varinfo;
}

let dummyVar = makeVarinfo false "_sdelay_foo" voidType

let sdelayfuns = {
  sdelay_init = dummyVar;
  start_timer_init  = dummyVar;
  fdelay_init = dummyVar;
  gettime = dummyVar;
  timer_create = dummyVar;
  sig_setjmp = dummyVar;
  fdelay_start_timer = dummyVar;
  critical_start = dummyVar;
  critical_end = dummyVar;
  pthread_create = dummyVar;
  pthread_join = dummyVar;
  log_trace_init = dummyVar;
  log_trace_previous_id = dummyVar;
  log_trace_init_task = dummyVar;
  log_trace_execution = dummyVar;
  log_trace_release = dummyVar;
  log_trace_arrival = dummyVar;
  log_get_time = dummyVar;
  htc_get = dummyVar;
  htc_unget = dummyVar;
  htc_reserve = dummyVar;
  htc_putmes = dummyVar;
  fifo_init = dummyVar;
  fifo_read = dummyVar;
  fifo_write = dummyVar;
  simsp_equal = dummyVar;
  spolicy_set = dummyVar;
  compute_priority = dummyVar;
  nelem = dummyVar;
  blocksignal = dummyVar;

}



let sdelay_init_str = "ktc_sdelay_init"
let start_timer_init_str   = "ktc_start_time_init"
(*let start_timer_init_str   = "sdelay"*)
let fdelay_init_str = "ktc_fdelay_init"
let gettime_str = "ktc_gettime"
let timer_create_str  = "ktc_create_timer"
let sig_setjmp_str = "__sigsetjmp"
let fdelay_start_timer_str = "ktc_fdelay_start_timer"
let critical_start_str  = "ktc_critical_start"
let critical_end_str = "ktc_critical_end"
let pthread_create_str = "pthread_create"
let pthread_join_str = "pthread_join"
let log_trace_previous_id_str = "log_trace_end_id"
let log_trace_init_str = "fopen"
let log_trace_init_task_str = "log_trace_init_tp"
let log_trace_arrival_str = "log_trace_arrival"
let log_trace_execution_str = "log_trace_execution"
let log_trace_release_str = "log_trace_release"
let log_get_time_str = "clock_gettime"
let htc_get_str = "ktc_htc_getmes"
let htc_unget_str = "ktc_htc_unget"
let htc_reserve_str = "ktc_htc_reserve"
let htc_putmes_str = "ktc_htc_putmes"
let fifo_init_str = "ktc_fifo_init"
let fifo_read_str =  "ktc_fifo_read"
let fifo_write_str = "ktc_fifo_write"
let simsp_equal_str = "ktc_simpson"
let spolicy_set_str = "ktc_set_sched"
let compute_priority_str = "populatelist"
let nelem_str = "nelem"
let blocksignal_str = "ktc_block_signal"


let sdelay_function_names = [
  sdelay_init_str;
  start_timer_init_str;
  fdelay_init_str;
  gettime_str;
  timer_create_str;
  sig_setjmp_str;
  fdelay_start_timer_str;
  critical_start_str;
  critical_end_str;
  pthread_create_str;
  pthread_join_str;
  log_trace_init_str;
  log_trace_previous_id_str;
  log_trace_init_task_str;
  log_trace_arrival_str;
  log_trace_execution_str;
  log_trace_release_str;
  log_get_time_str;
  htc_get_str;
  htc_unget_str;
  htc_reserve_str;
  htc_putmes_str;
  fifo_init_str;
  fifo_read_str;
  fifo_write_str;
  simsp_equal_str;
  spolicy_set_str;
  compute_priority_str;
  nelem_str;
  blocksignal_str;
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
  let init_type = TFun(intType, Some["unit",  intType, [];],
                     false, [])
  in
  let end_type = TFun(intType, Some["intrval", intType, [];],
                     false, [])
  in
  sdelayfuns.sdelay_init <- focf sdelay_init_str init_type;
  sdelayfuns.start_timer_init <- focf start_timer_init_str   end_type;
  sdelayfuns.fdelay_init <- focf fdelay_init_str init_type;
  sdelayfuns.gettime <- focf gettime_str init_type;
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
  sdelayfuns.log_get_time <- focf log_get_time_str init_type;
  sdelayfuns.pthread_join <- focf pthread_join_str init_type;
  sdelayfuns.log_trace_init <- focf log_trace_init_str init_type;
  sdelayfuns.log_trace_previous_id <- focf log_trace_previous_id_str init_type;
  sdelayfuns.log_trace_init_task <- focf log_trace_init_task_str init_type;
  sdelayfuns.log_trace_arrival <- focf log_trace_arrival_str init_type;
  sdelayfuns.log_trace_execution <- focf log_trace_execution_str init_type;
  sdelayfuns.log_trace_release <- focf log_trace_release_str init_type;
  sdelayfuns.fifo_init <- focf fifo_init_str init_type;
  sdelayfuns.fifo_read <- focf fifo_read_str init_type;
  sdelayfuns.fifo_write <- focf fifo_write_str init_type;
  sdelayfuns.simsp_equal <- focf simsp_equal_str init_type;
  sdelayfuns.spolicy_set <- focf spolicy_set_str init_type;
  sdelayfuns.nelem <- focf nelem_str init_type;
  sdelayfuns.blocksignal <- focf blocksignal_str init_type;
  sdelayfuns.compute_priority <- focf compute_priority_str init_type


let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) lv =
  (*let time_unit = if ((L.length argL) = 3 && not (isZero (L.hd argL))) then (E.s (E.error "%s:%d: error : unknown resolution of timing point" loc.file loc.line)) else (L.nth argL 2) in*)
  let time_unit = (L.nth argL 2) in
  let f, l, deadline, period ,tunit, s, t_id = mkString loc.file, integer loc.line, L.hd argL, (L.nth argL 1), time_unit, mkAddrOf((var structvar)), (List.hd (List.rev argL))  in
  [Call(lv,v2e sdelayfuns.sdelay_init, [deadline;period;tunit;s;t_id;], loc)]

let makeelemInstr chan tail head lv loc =
  [Call(lv,v2e sdelayfuns.nelem, [mkAddrOf(var chan); Lval(var head); Lval(var tail)], loc)]

let makeLogTraceInit filepointer name loc =
    Call(Some(filepointer), v2e sdelayfuns.log_trace_init, [name; (mkString "w")], loc)

let makeLogTracePreviousID filepointer id stime loc =
    Call(None, v2e sdelayfuns.log_trace_previous_id, [filepointer;id; stime], loc)

let makeLogTraceTask filepointer last_arrival itime loc =
    Call(None, v2e sdelayfuns.log_trace_init_task, [filepointer; Cil.zero;
    last_arrival; itime], loc)


let makeLogTraceArrival file_pointer tpid interval resolution arrival_pointer
itime loc  =
    Call(None,v2e sdelayfuns.log_trace_arrival, [file_pointer;tpid;
    interval;resolution;arrival_pointer], loc)


let makeLogTraceExecution file_pointer stime loc =
    Call(None,v2e sdelayfuns.log_trace_execution, [file_pointer;stime], loc)

let makeLogTraceRelease file_pointer last_arrival itime stime interval loc =
    Call(None,v2e sdelayfuns.log_trace_release,
    [file_pointer;last_arrival;itime;stime; interval], loc)

let makeLogGetTime itime  loc =
    Call(None,v2e sdelayfuns.log_get_time, [Cil.zero; (mkAddrOf (var itime))],
    loc)


let makeSdelayEndInstr fdec (structvar : varinfo) (timervar : varinfo) (tp : varinfo) (signo : int)=
  let s =  mkAddrOf((var structvar)) in
  let start_time_init = Call(None, v2e sdelayfuns.start_timer_init, [s;], locUnknown) in
  let t =  mkAddrOf((var timervar)) in
  let handlrt = mkAddrOf((var tp)) in
  let ktctime_var = findLocalVar fdec.slocals ("ktctime") in
  let itime_init_start_time = Set((Var(ktctime_var), NoOffset), v2e
        structvar, locUnknown) in
  let timer_init = Call(None, v2e sdelayfuns.timer_create, [t; v2e timervar; handlrt; (integer signo);], locUnknown) in
  [mkStmtOneInstr start_time_init; mkStmtOneInstr itime_init_start_time; mkStmtOneInstr timer_init]

(*
let makeSdelayEndInstr (structvar : varinfo) (timervar : varinfo) (tp : varinfo) (signo : int)=
  let t =  mkAddrOf((var timervar)) in
  let handlrt = mkAddrOf((var tp)) in
  let timer_init = Call(None, v2e sdelayfuns.timer_create, [t;handlrt; (integer signo);], locUnknown) in
  [mkStmtOneInstr timer_init]
*)

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) (retjmp) (signo) tpstructvar lv : instr list =
  let time_unit = if ((L.length argL) = 3 && not (isZero (L.hd argL))) then mkString  (E.s (E.error "%s:%d: error : unknown resolution of timing point" loc.file loc.line))  else (L.nth argL 2) in
  let f, l, deadline, period, tunit, s, t_id = mkString loc.file, integer loc.line, L.hd argL, (L.nth argL 1), time_unit, mkAddrOf((var structvar)), (List.hd(List.rev argL)) in
  let waitingOffset = match tpstructvar.vtype with
		      | TComp (cinfo, _) -> Field (getCompField cinfo "waiting", NoOffset) in
  let waitingConditionInstr = Set((Var tpstructvar, waitingOffset), Cil.one, locUnknown) in
  [waitingConditionInstr; Call(lv,v2e sdelayfuns.fdelay_init, [deadline;period;tunit;s;t_id;(v2e retjmp); signo;], loc)]

let makegettimeInstr lv (structvar : varinfo) (argL : exp list) loc =
	let tunit, s =  L.hd argL, mkAddrOf((var structvar)) in
	[Call(lv,v2e sdelayfuns.gettime, [tunit;s;], loc)]



let makespolicysetInstr runtime period deadline policy =
  Call(None,v2e sdelayfuns.spolicy_set, [v2e policy; v2e runtime; v2e deadline; v2e period], locUnknown)

let makeCriticalStartInstr (sigvar : varinfo) (loc: location) =
	let argSig = mkAddrOf (var sigvar) in
	i2s	(Call(None, v2e sdelayfuns.critical_start, [argSig;], loc) )

let makeCriticalEndInstr (sigvar : varinfo) (loc: location)=
        let argSig = mkAddrOf (var sigvar) in
        i2s ( Call(None, v2e sdelayfuns.critical_end, [argSig;], loc) )

let makePthreadCreateInstr (threadvar : varinfo) (funvar : varinfo) argList
(loc:location) fdec =
	let addrThread = mkAddrOf(var threadvar) in
	let nullptr = (Cil.mkCast Cil.zero Cil.voidPtrType) in
    let itime = findLocalVar fdec.slocals ("ktcitime") in
	(*let addrFun = mkAddrOf(var funvar) in
	i2s ( Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero; addrFun; Cil.zero;], loc)) *)
	let ret = if (L.length argList) = 0 then
	Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero  ; (mkAddrOf
    (var funvar)); nullptr], loc)
	else
	Call(None, v2e sdelayfuns.pthread_create, [addrThread; Cil.zero ; (mkAddrOf
    (var funvar)); mkAddrOf (var itime)], loc)
	in ret



let makePthreadJoinInstr fdec (threadvar : varinfo)  =
	let threadvoidptr = makeLocalVar fdec (threadvar.vname^"_join") (voidPtrType) in
          mkStmt (Instr([(Call(None, v2e sdelayfuns.pthread_join, [v2e threadvar; (mkAddrOf (var threadvoidptr));], locUnknown))]))

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


let rec typeofe e =
match e with
|Const(_) -> E.log "1"
|Lval(_) -> E.log "2"
|SizeOf(_) -> E.log "3"
|SizeOfE(_) -> E.log "4"
|AlignOf(_)  -> E.log "5"
|AlignOfE(_) -> E.log "6"
|UnOp(_,_,_) -> E.log "7"
|BinOp(_,_,_,_) -> E.log "8"
|CastE(_,e1) -> typeofe e1; E.log "9"
|AddrOf(_) -> E.log "10"
|StartOf(_) -> E.log "11"


let policyValue data hstm runtime deadline period priority policy list_dl list_pr setschedvar =
	let succTP = retTimingPointSucc hstm data in
	let tpinstr = getInstruction succTP in
	let (vl_run, vl_dl, vl_period) = (match tpinstr with
		    |Call(_,Lval(Var vf,_),argList,_) -> let vl_run = getruntime (List.hd argList) in
							 let vl_dl = getdl (List.hd argList) in
							 let vl_period = getperiod (List.hd argList) in
								(vl_run, vl_dl, vl_period)
		    | _ ->  E.s(E.bug "Error: label") ) in
	let runstm =  Set((var runtime), (vl_run), locUnknown) in
	let dlstm =  Set((var deadline), (vl_dl), locUnknown) in
	let perstm =  Set((var period), (vl_period), locUnknown) in
	let add_dl = Set((Var list_dl, Index (integer !policyindex, NoOffset)), vl_dl, locUnknown) in
	let add_pr = Set((Var list_pr, Index (integer !policyindex, NoOffset)), vl_period, locUnknown) in
	let setsched = makespolicysetInstr runtime deadline period policy in
	let polist = [runstm; dlstm; perstm; setsched] in
	let ifcond = If((v2e setschedvar), mkBlock [(mkStmt (Instr(polist)))], mkBlock[], locUnknown) in
	let isdlval = (match vl_dl with
		      |Lval(_) -> ()
		      |_ -> lstinstpolicy := add_dl :: !lstinstpolicy; 	policyindex := !policyindex + 1 ;  ()) in
	let isprval = (match vl_period with
		      |Lval(_) -> ()
		      |_ -> lstinstpolicy := add_pr :: !lstinstpolicy; ()) in
	ifcond





let maketimerfdelayStmt structvar argList tpstructvar timervar retjmp firmStmt =
	 let offset' = match tpstructvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "env", NoOffset) in
	 let waitingOffset = match tpstructvar.vtype with
			   | TComp (cinfo, _) -> Field (getCompField cinfo "waiting", NoOffset) in
	let waitingConditionStmt = mkStmtOneInstr(Set((Var tpstructvar, waitingOffset), Cil.zero, locUnknown)) in
	let buf = Lval(Var tpstructvar, offset') in
	let i = Cil.one in
 	let argL = if L.length argList < 5 then argList else (L.tl argList) in
	let time_unit = L.nth argL 2 in
	let intr, tunit, timr, s = L.nth argL 1, time_unit, v2e timervar, v2e structvar in
	let sigInt = Call(Some(var retjmp), v2e sdelayfuns.sig_setjmp, [buf;i;], locUnknown) in
	let letjmpto = findgoto labelHash firmStmt in
	(*let goto_label = dummyStmt in *)
	let goto_label = mkStmt (Goto(ref letjmpto, locUnknown))  in
	let ifBlock = ifBlockFunc goto_label retjmp  in
	let st = mkAddrOf (var structvar) in
	let startTimer = Call(None, v2e sdelayfuns.fdelay_start_timer, [intr; tunit;timr;st;], locUnknown) in
	  [mkStmtOneInstr sigInt; ifBlock; waitingConditionStmt; mkStmtOneInstr startTimer ]

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
	let blocksg = i2s (Call(None, v2e sdelayfuns.blocksignal, [Cil.zero], locUnknown)) in
	let newstmnt = List.append pthreadjoin_stmt [blocksg] in
	let revList = List.append newstmnt revList in
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
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "ktc_sdelay_init") ->  true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "ktc_fdelay_init")  -> true
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


let getLValChan e =
match e with
|CastE(_, AddrOf(e1)) -> e1



let getExpNameR e =
        match e with
        |BinOp(_, SizeOfStr s1, e1, _) -> (*typeofe e1;*) (s1, e1)
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

let isBinopOperation hstm data =
	let succTP = retTimingPointSucc hstm data in
	let tpinstr = getInstruction succTP in
	match tpinstr with
	|Call(_,Lval(Var vi,_),argList,loc) -> ( match (List.hd argList) with
							|BinOp(_, _, _, _) -> false
							|_ -> true)
	|_ -> true

let isSameSucc argHead hstm data  =
	let succi = ( match (argHead) with
			|Const(CInt64(i, _, _))-> i64_to_int i
			|_ -> -10) in
	let succTP = retTimingPointSucc hstm data in
	let tpinstr = getInstruction succTP in
	(match tpinstr with
	|Call(_,Lval(Var vi,_),argList,loc) -> ( match (List.hd argList) with
							|Const(CInt64(i, _, _)) when ((i64_to_int i) = succi) -> false
							|_ -> true)
	|_ -> true)

class policydetail filename data runtime deadline period priority policy list_dl list_pr setsched = object(self)
	inherit nopCilVisitor
	method vstmt (s :stmt) =
	let action s =
	(match s.skind with
	|Instr il when il <> [] -> (match (List.hd il) with
	          				|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "fdelay") ->
							if ((isZeroTimingPointSucc s data)) && (isBinopOperation s data) && (isSameSucc (List.hd argList) s data) then
							   let nb = policyValue data s runtime deadline period priority policy list_dl list_pr setsched in
							   let setschedblock = mkBlock [(mkStmtOneInstr (List.hd il)); mkStmt nb; mkStmt (Instr(List.tl il))] in
							   s.skind <- (Block(setschedblock)); s
							else
							  s
                  				|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "sdelay") ->
								if ((isZeroTimingPointSucc s data)) && (isBinopOperation s data) && (isSameSucc (List.hd argList)  s data)  then
								 let nb = policyValue data s runtime deadline period priority policy list_dl list_pr setsched in
								   let setschedblock = mkBlock [(mkStmtOneInstr (List.hd il)); mkStmt nb; mkStmt (Instr(List.tl il))] in
							   s.skind <- (Block(setschedblock)); s
								else
								   s
		  				| _ ->  s)
	| _ ->  s)
	in ChangeDoChildrenPost(s, action)
end
let rec getsumdelay il lst =
	match lst with
	| h :: rest -> (match h with
		     |Call(info,Lval(Var vi,vo),argList,loc) when (vi.vname = "sdelay") -> let newarg = BinOp(PlusA, List.hd argList, il, intType) in
											   let newarglst = newarg :: (List.tl argList) in
										           let newil = Call(info,Lval(Var vi,vo), newarglst,loc) in
											   getsumdelay (List.hd newarglst) rest
 		     |Call(info,Lval(Var vi,vo),argList,loc) when (vi.vname = "fdelay") -> let newarg = BinOp(PlusA, List.hd argList, il, intType) in
											   let newarglst = newarg :: (List.tl argList) in
										           let newil = Call(info,Lval(Var vi,vo), newarglst,loc) in
											   getsumdelay (List.hd newarglst) rest
		     | _ -> (il, lst) )
	| [] -> (il, lst)

let rec mergedList aux lst  =
	match lst with
	| h :: rest -> (match h with
			|Call(info,Lval(Var vi,vo),argList,loc) when (vi.vname = "sdelay") ->  let (newarg, newlst) =  getsumdelay (List.hd argList) rest in											     let newarg = newarg :: (List.tl argList) in
											   let newil = Call(info,Lval(Var vi,vo),newarg,loc) in
											   let aux = newil :: aux in																	mergedList aux newlst 								    |Call(info,Lval(Var vi,vo),argList,loc) when (vi.vname = "fdelay") -> let (newarg, newlst) =  getsumdelay (List.hd argList) rest in
											  let newarg = newarg :: (List.tl argList) in
											  let newil = Call(info,Lval(Var vi,vo),newarg,loc) in
											  let aux = newil :: aux in
												mergedList aux newlst
			| _ -> let aux = h :: aux in mergedList aux rest )
	| [] -> aux

let rec mergeStmt s =
	match s.skind with
	| Instr (il) -> mkStmt (Instr(List.rev (mergedList [] il)))
	| _ -> s


class merger filename fdec = object(self)
   inherit nopCilVisitor

	method vblock b =
	let action b =
	   let s = b.bstmts in
	   let mods = List.map mergeStmt s in
	    	b.bstmts <- mods; b
	   in ChangeDoChildrenPost(b, action)

end

let rec addArrivalTime lst sum =
    match lst with
    | (name, at):: rest -> addArrivalTime rest (at + sum)
    | [] -> sum

let rec uniqueTaskPair task_list task_arrival_time_list =
    match task_list with
    |h :: rest -> (let lst = (((List.filter (fun a -> (fst a) = h )
    task_arrival_time_list))) in
    let sarrival = addArrivalTime  lst 0 in
    (h, sarrival) :: (uniqueTaskPair rest task_arrival_time_list))
    |[] -> []


let rec gcd u v =
  if v <> 0 then (gcd v (u mod v))
  else (abs u)

let lcm m n =
  match m, n with
  | 0, _ | _, 0 -> 0
  | m, n -> abs (m * n) / (gcd m n)

let calculateHyperperiod tlist =
    let hyperiod = List.fold_right lcm (tlist) 1 in
    E.log "Hyperperiod %d\n" hyperiod; hyperiod

(*
let rec unrolledJob num p j b w d pr nnow =
    match nnow with
    | 0 -> []
    | 1 -> ([pr; 1; 0; j; b; w; d; pr]) :: (unrolledJob num
    p j b w d pr (nnow -1))
    (*|  _ -> let md = (nnow mod num) in
    if (md <> 1) then
    (([pr; (md); md*p; ((md*p)+j); b; w; (md*p + d);pr]) :: (unrolledJob num
    p j b w d pr (nnow -1))) else [] :: (unrolledJob num p j b w d pr (nnow -1))*)
    |  _ -> let md = (nnow mod num) in
    if (md <> 1) then
    (([pr; (md); md*p; ((md*p)+j); b; w; (md*p + d);pr]) :: (unrolledJob num
    p j b w d pr (nnow -1))) else [] :: (unrolledJob num p j b w d pr (nnow -1))
*)

let rec unrolledJob num p j b w d pr nnow k =
    (*let _ = E.log "unrolledJob %d" nnow in*)
    match nnow with
    | t when t = num -> []
    | 0 -> ([pr; 0; 0; j; b; w; d; d; k]) :: (unrolledJob num p j b w d pr (nnow
    + 1) k)
    (*|  _ -> let md = (nnow mod num) in
    if (md <> 1) then
    (([pr; (md); md*p; ((md*p)+j); b; w; (md*p + d);pr]) :: (unrolledJob num
    p j b w d pr (nnow -1))) else [] :: (unrolledJob num p j b w d pr (nnow -1))*)
    |  _ ->  ([pr; (nnow); nnow*p; ((nnow*p)+j); b; w; (nnow*p + d);  nnow*p +
    d; k]) :: (unrolledJob num
    p j b w d pr (nnow + 1)) k

let unrollOneFrame tlist hp id =
    let telem = List.hd tlist in
    let period = int_of_string (List.nth telem 1) in
    let num_job = hp/period in
    let n = 0 in
    let k_int = if ((List.nth telem 6) = "fdelay") then 0 else 1 in
    unrolledJob (num_job ) (int_of_string ((List.nth telem 1))) (int_of_string
    (List.nth telem 2)) (int_of_string (List.nth telem
    3))  (int_of_string (List.nth telem 4)) (int_of_string (List.nth telem 5))
    id n (k_int)

    (*
let rec auxUnrollMultiFrame tlist num_itr id =
    match num_itr with
    | 0 -> []
    |


let unrollMultiFrame tlist hp id tname uniquelist =
    let (name, period) = List.find (fun a -> (fst a) = tname) uniquelist in
    let num_itr = hp/period in
    auxUnrollMultiFrame tlist num_itr id

*)

let unrollSegment telem next_d jlist id  jid =
    (*let _ = E.log "urollSegment %d\n" jid in*)
    let [name; p; j; b; w; d;k] = telem in
    let p_int = int_of_string p in
    let d_int = int_of_string d in
    let j_int = int_of_string j in
    let next_d_int = int_of_string next_d in
    let k_int = if (k = "fdelay") then 0 else 1 in
    match jlist with
    | [] -> [(int_of_string id); (jid); p_int; p_int + j_int ; (int_of_string b);
    (int_of_string w);  (p_int + next_d_int); (p_int + next_d_int); k_int]
    | _ -> let last_p = List.nth (List.hd (jlist)) 2 in
           (*let _ = E.log "last p %d\n" last_p in*)
    [(int_of_string id); jid;
    (last_p + p_int); (last_p + p_int+j_int);
    (int_of_string b); (int_of_string w);(last_p +
    p_int+next_d_int); (last_p +
    p_int+next_d_int); k_int]

let rec unrollMultiFrame tlist hp id tname l jlist =
    let len = List.length tlist in
    (*let _ = E.log "unrollMUltiframe %d %s %d\n" (l) tname len in*)
    match l with
    | t when t = (len) -> jlist
    | _ -> let jlst = unrollSegment (List.nth tlist l) (List.nth (List.nth tlist
    ((l+1) mod len)) 5) jlist id ((List.length jlist)+1) in
         let nelist = jlst :: jlist in
          unrollMultiFrame tlist hp id tname (l+1) nelist

let rec recUnrollSegment tlist hp id tname iter jlist =
    (*let _ = E.log "recUnrollSegment %d\n" iter in*)
    match iter with
    | 0 -> jlist
    | _ -> let jlst = unrollMultiFrame tlist hp id tname 0 jlist in
            (*let jlst = [] in*)
           (*let njlst = List.append jlst jlist in*)
            (*unrollMultiFrame tlist hp id tname (iter - 1) njlst*)
           recUnrollSegment tlist hp id tname (iter -1 ) jlst


let add_period lst b =
    let a = int_of_string (List.nth lst 1) in
    (*let _ = E.log "add period %d\n" a in*)
    a + b

let unrollMultiFrameAux tlist hp id tname =
    let sum_period =  List.fold_right (add_period) (tlist) 0 in
    let _ = E.log "sum period %s %d\n" tname sum_period in
    let _ = E.log "hyper period %s %d\n" tname hp in
    let iter = hp/sum_period in
    let _ = E.log "iter %d\n" iter in
    let [name; p; j; b; w; d;k] = List.hd (List.rev tlist) in
    let [n1; p1; j1; b1; w1; d1;k1] = List.hd tlist in
    let k_int = if (k = "fdelay") then 0 else 1 in
    let nlst = List. rev (List.tl (recUnrollSegment tlist hp id tname iter [])) in
    [(int_of_string id); 0; 0;( int_of_string j1);
    (int_of_string b); (int_of_string w); (int_of_string d1); (int_of_string
    d1);k_int] :: nlst


let unrollOneTask tlist hp id tname =
    let l = List.length tlist in
    if (l = 1) then (unrollOneFrame tlist hp id ) else (
        if (l =  0) then [] else (unrollMultiFrameAux
    (List.rev tlist) hp (string_of_int id) tname))


let find_offset jlist tskname =
    let olist = List.find (fun [tid; at; j; b; w; d;k] -> ((tid = tskname) & (int_of_string j) = 0) ) jlist in
    (int_of_string (List.nth olist 1))


let max_offset jlist =
    let olist = List.filter (fun [tid; at; j; b; w; d;k] -> ((int_of_string j) = 0)) jlist in
     let maxo = List.fold_right (Pervasives.max)
     (List.map (fun [tid; at; j; b; w; d;k] -> (int_of_string at)) olist) 0 in
     (E.log "max offset %d\n" maxo); maxo




let rec unrollToHyper hp tlist task_list jlist =
       match task_list with
       | name :: rest -> let onetskl = List.filter (fun a -> (List.nth a 0) =
           name) tlist in
                         let os = find_offset jlist name in
                         let unrolledlst = unrollOneTask (onetskl) (hp) (List.length
                         task_list)  name in
                         let ncsv1 = List.map (fun [tid; jid; amin; amax; cmin;
                         cmax; dl; pr;k] ->  [tid; jid; (
                         ((amin) + os)); amax; cmin; cmax;
                         (((dl) + os)); pr;k] )
                         (unrolledlst) in
                         let _ = E.log "a" in
                         let h_amin = List.nth (List.hd unrolledlst) 1 in
                         let _ = E.log "b" in
                         let ncsv2 = if (h_amin = 0) then ncsv1 else (List.tl ncsv1) in
                         List.append ncsv2 (unrollToHyper hp ((List.filter
                         (fun a -> (List.nth a 0) <> name)) tlist) rest jlist)
       |[] -> []

let to_csv_string ilist =
    List.map (fun a -> (string_of_int a)) ilist


let rec match_alist alist b w tid jid lst =
    match alist with
    | [ht; ha; hb; hw; habtmin; habtmax; dl] :: rst when (((int_of_string hw) = (int_of_string w))) ->
            match_alist rst b w tid jid ([tid; jid; habtmin; habtmax; hb; hw] :: lst)
    | [ht; ha; hb; hw; habtmin; habtmax; dl] :: rst when (((int_of_string hw) <> (int_of_string w))) ->
            match_alist rst b w tid jid (lst)
    |_ -> lst

    |_ -> lst

let rec create_abort_csv alist nlist lst =
    match nlist with
    | ([tid;jid; p; j; b; w; d;pr;k] :: rst) when (int_of_string k) = 1 -> let elem = match_alist alist b w tid jid [] in
                                                          create_abort_csv alist rst (List.append elem lst)
    | ([tid;jid; p; j; b; w; d;pr;k] :: rst) when (int_of_string k) <> 1 -> create_abort_csv alist rst lst
    |[] -> lst
(*let rec create_abort_csv alist nlist lst =
    match nlist with
    | ([tid;jid; p; j; b; w; d;pr;k] :: rst) when k = 0 -> let elem = List.find
    (fun a -> ((int_of_string (List.nth a 2)) = b) &&
    ((int_of_string (List.nth a 3)) = (w))) alist  in
                                                          create_abort_csv alist
                                                          rst ([tid; jid;
                                                          (int_of_string
                                                          (List.nth elem 4));
                                                          (int_of_string
                                                          (List.nth elem 5)); b;
                                                          w]::lst)
    | ([tid;jid; p; j; b; w; d;pr;k] :: rst) when k <> 0 -> lst
    |[] -> lst



let rec create_abort_csv alist jlist nlst =
    match jlist with
    | hx :: rst -> let tid = List.hd hx in
                  let texists = List.exists (fun a -> if (List.hd a = tid) then true else false) alist in
                  let auxlist = (if (texists) then
                      (let ax = List.find (fun a -> if (List.hd a = tid) then true else false) alist  in
                  [tid; List.nth hx 1; List.nth hx 6; List.nth hx 6; List.nth ax 2; List.nth ax 3] :: nlst)
                      else nlst) in
                  create_abort_csv alist rst auxlist
    | [] -> nlst*)


let add_cmax_win lst b =
    let a = (List.nth lst 5) in
    (*let _ = E.log "add period %d\n" a in*)
    a + b

let max_rel_win lst b =
    let a = (List.nth lst 5) in
    (*let _ = E.log "add period %d\n" a in*)
    Pervasives.max a b


let rec compute_observation_window win ujblist tp t =
    if (tp <> t) then
        let tn = List.fold_right (add_cmax_win) (List.filter (fun a -> ((tp < (List.nth a 3)) & ((List.nth a 3) <= t))) ujblist) t in
        let cond = ((List.exists (fun a -> (((List.nth a 2) <= tn) && (tn <
        (List.nth a 3)))) ujblist) || (tn < win)) in
        let newtn = if ((t = tn) && cond) then List.fold_right (max_rel_win) (List.filter (fun a -> ((tn < (List.nth a 3)))) ujblist) 0 else tn in
            compute_observation_window win ujblist t tn
    else
        let _ =(E.log "Observation Window %d" t) in t

let uniq l =
  let rec tail_uniq a l =
    match l with
      | [] -> a
      | hd::tl -> tail_uniq (hd::a) (List.filter (fun x -> x  != hd) tl) in
  tail_uniq [] l

let findHyperperiod tlist alist jlist =
    let task_arrival_pair = (List.map (fun a -> ((List.nth a 0), (int_of_string
    (List.nth a 1))))) tlist in
    let task_list = List.map (fun a -> List.nth a 0) tlist in
    let unique_task_arrival_pair = uniqueTaskPair (task_list) ((task_arrival_pair)) in
    let hp = calculateHyperperiod (List.map (fun a -> (snd a))
    unique_task_arrival_pair) in
    let maxos = max_offset jlist in
    let utask_list = uniq task_list in
    let ujblist = (unrollToHyper (hp + maxos) tlist (utask_list) jlist) in
    let ncsv = List.map (to_csv_string) (ujblist) in
       (* let ncsv2 = if (int_of_string h_amin = 0) then ncsv1 else (List.tl
        ncsv1) in*)
    let t = List.fold_right Pervasives.max (List.map (fun a -> List.nth a 3)
    ujblist) 0 in
    let _ = E.log "done\n" in
    let new_win = compute_observation_window (hp + maxos) ujblist 0 t in
    let ujblist = (unrollToHyper (new_win) tlist (utask_list) jlist) in
    let ncsv = List.map (to_csv_string) (ujblist) in
    (*let _ = E.log "new_win %d" new_win in*)
    let nncsv0 = List.map (fun [tid; jid; amin; amax; cmin; cmax; dl; pr;k] ->
        [tid; jid; amin; amax; cmin; cmax; dl; pr] ) ncsv in
    let nncsv = ["Task ID"; "Job ID"; "Arrival min"; "Arrival max"; "Cost min";
    "Cost max"; "Deadline"; "Priority"] :: (nncsv0) in
    let _ = Csv.save "kind.csv" ncsv in
    let _ = Csv.save "job.csv" nncsv
    in
    let abortcsv =  (match alist with
                    |[] -> E.log "alist empty here"; []
                    |_ -> E.log "alist not empty"; List.rev (create_abort_csv alist (ncsv) [])) in
    let abortncsv = ["Task ID"; "Job ID"; "TMIN"; "TMAX"; "CMIN";
    "CMAX"] :: abortcsv in
    let _ = Csv.save "action.csv" abortncsv
in ()

let read_data fname =
  Csv.load fname
  |> List.map (function [src; bcet; wcet; jitter; abort; dst] -> {src; bcet; wcet; jitter; abort; dst}
                      | _ -> failwith "read_data: incorrect file")

let filter_edges s d t =
    List.find (fun a -> (a.src = s) && (a.dst = d) ) t

let filter_nodes s t =
    List.find (fun a -> (a.src = s)) t

let maxEx a b  =
    let aint = int_of_string a in
    if (aint > b) then aint else b

let minEx a b =
    let aint = int_of_string a in
    if (aint < b) then aint else b

let findExecutionTime tname src dst =
    let tnew = read_data tname in
    let noheader = List.tl tnew in
    let edge = filter_edges (src) (dst) noheader in
    let maxexe = edge.wcet in
    let minexe = edge.bcet in
    ((int_of_string maxexe), (int_of_string minexe))

let findExecutionTimeSrc tname src =
    let tnew = read_data tname in
    let noheader = List.tl tnew in
    let edge = filter_nodes (src) noheader in
    let maxexe = edge.wcet in
    let minexe = edge.bcet in
    ((int_of_string maxexe), (int_of_string minexe))


let findJitter tname src =
    let tnew = read_data tname in
    let noheader = List.tl tnew in
    let node = filter_nodes (src) noheader in
    (int_of_string node.jitter)


let findExecutionAbortTime tname src =
    let tnew = read_data tname in
    let noheader = List.tl tnew in
    let edge = filter_nodes (src) noheader in
    ((int_of_string edge.abort), (int_of_string edge.abort))


let tfgFindID jnodes =
 List.length jnodes


let addJsonNodes jnodes arrival_time deadline kind tname d =
    let _ = E.log "deadline %d\n" in
    let id = tfgFindID jnodes in
    let j = findJitter tname  (string_of_int (id+1)) in
    let (wcet,bcet) = findExecutionTimeSrc tname (string_of_int (id+1)) in
    let (min_abort, max_abort) = findExecutionAbortTime tname (string_of_int
    (id+1)) in
    let _ = if ((max_abort) <> 0 && (max_abort <> 1000000000000) ) then
        (abortlist :=  [tname; (string_of_int arrival_time);  (string_of_int bcet); (string_of_int wcet); (string_of_int
        min_abort); (string_of_int max_abort); (string_of_int deadline)] ::
        !abortlist) in
    (joblist := ([tname; (string_of_int arrival_time); (string_of_int j);
    (string_of_int bcet); (string_of_int wcet); (string_of_int deadline); kind] ::
        !joblist));
    ((if ((j) <> 0) then (csvlist := ([tname; (string_of_int arrival_time); (string_of_int j);
    (string_of_int 0); (string_of_int wcet); (string_of_int deadline);kind] ::
        !csvlist))));    [`Assoc[("id",`Int(id+1)); ("a", `Int(arrival_time)); ("d", `Int(arrival_time));
    ("kind", `String(kind));("j",`Int(j))]]

let rec addJsonEdges len clen jedges tname =
    (*let _ = E.log "addJsonEdges %d \n" (clen) in*)
    match clen with
    | 0 -> jedges
    | _ -> let d = if (clen = len) then 1 else (clen + 1) in
            (*let _ = E.log "%s" tname in*)
           let (wcet,bcet) = findExecutionTime tname (string_of_int clen)
           (string_of_int d) in
           let e = `Assoc[("src", `Int(clen));("dst", `Int(d)); ("b", `Int(bcet)); ("w",
              `Int(wcet))] :: jedges in
            let nlen = clen - 1 in
            addJsonEdges len nlen e tname

let completeJsonEdges jnodes tname =
    let len = List.length jnodes in
    let jedgeslist = addJsonEdges len len [] tname in
    jedgeslist

let tfgGetValueInt t =
    let topt = Cil.isInteger t in
    let tinit = (match topt with
                 |Some(at) -> i64_to_int at
                 |None -> raise (Eson "arrival time not
                                    Int")) in
            tinit

let tfgTimeInMicroSec tv res =
    let t = tfgGetValueInt tv in
    let n = tfgGetValueInt res in
    let powup = 10.0 ** ((float_of_int n) +. 6.0) in
    (int_of_float powup) * t


class tfgMinus fdc = object(self)
    inherit nopCilVisitor
    method vinst (i : instr) =
        let action [i] =
            match i with
            |Call(_,Lval(Var vi,_),argL, loc) when (vi.vname = "sdelay" ||
                                    vi.vname = "fdelay") ->(let argList = if
                                        ((L.length argL) < 5) then (argL) else
                                            (List.tl argL) in
                                    let (at, dl, res) = ((List.nth argList 0), (List.nth argList 1), (List.nth argList 2)) in
                                    let arrival_time_int = tfgTimeInMicroSec at res in
                                    let deadline_time_int = tfgTimeInMicroSec dl res in
                                    let deadline_int = tfgGetValueInt dl in
                                    let _ = if (!offsetvar = 0) then (offsetlist := (arrival_time_int) :: !offsetlist) in
                                    let _ = (offsetvar := 1) in
                                    let kind = vi.vname in
                                    let _ = (if (arrival_time_int > -1404 &&
                                    deadline_int < 2147483640) then
                                            let newnode = addJsonNodes !jnodeslist arrival_time_int
                                            deadline_time_int kind
                                            fdc.svar.vname deadline_int in
                                            jnodeslist := List.append
                                            !jnodeslist newnode) in
                                    [i])
            |_ -> [i] in
        ChangeDoChildrenPost([i], action)
end



class profilingAdder filename logname lastarrival stime itime fdec id_var
count_var = object(self)
    inherit nopCilVisitor
    val mutable counter = 0
    method vinst (i : instr) =
    let action [i] =
        match i with
        |Call(_,Lval(Var vi,_),argList, loc) when (isFunTask vi) ->
                let logstart = findCompinfo filename "timespec" in
                let itimeexist = List.exists (fun v -> v.vname = "ktcitime")
                fdec.slocals in
                let logstart_var = if (itimeexist) then (findLocalVar
                fdec.slocals ("ktcitime")) else (makeLocalVar fdec ("ktcitime")
                (TComp(logstart,[]))) in
                [i]
        |Call(_,Lval(Var vi,_),argList, loc) when ((vi.vname = "sdelay" ||
        vi.vname = "fdelay") & (fdec.svar.vname <> "main")) ->
               let inc_count_instr = counter <- counter + 1; Set((Var(count_var),
               NoOffset), BinOp(PlusA, v2e id_var, (integer counter), intType), locUnknown) in
               let previous_id_instr = makeLogTracePreviousID (v2e logname) (v2e
               count_var) (v2e stime) locUnknown in
               let trace_arrival_instr = makeLogTraceArrival (v2e logname)
               (v2e count_var) (List.nth argList 1) (List.nth
               argList 2) (mkAddrOf (var lastarrival)) (mkAddrOf (var itime)) locUnknown in
               let trace_release_instr = makeLogTraceRelease (v2e logname)
               (v2e lastarrival) (v2e itime) (mkAddrOf (var stime))
               (List.nth argList 1) locUnknown in
               let trace_end_instr = makeLogTraceExecution (v2e logname) (v2e
               stime) locUnknown in
               [trace_end_instr; i; inc_count_instr; inc_count_instr; trace_arrival_instr; trace_release_instr]
        |_ -> [i] in
        ChangeDoChildrenPost([i], action)
end



class sdelayReportAdder filename fdec structvar tpstructvar timervar (ret_jmp : varinfo) data fname sigvar  signo = object(self)
  inherit nopCilVisitor

       method vinst (i :instr) =
        let sname = "fdelay" in
        let action [i] =
        match i with
	(*|Call(lv,Lval(Var vi,_),argList,loc) when (vi.vname = "nelem") ->  let arg = List.hd argList in
									     let channame = (match arg with
											   |Lval(Var vi, _) -> vi.vname) in
									     let fifothrdqu = findGlobalVar filename.globals channame in
						   			     let fifochanlist = findGlobalVar filename.globals (channame^"ktclist") in
						                             let fifocount = findGlobalVar filename.globals (channame^"ktccount") in
						                             let fifotail= findGlobalVar filename.globals (channame^"ktctail") in
					                                     makeelemInstr  fifothrdqu fifocount fifotail lv loc *)
    |Call(lv,Lval(Var vi,_),argList,loc) when (vi.vname = "sdelay") -> if L.length argList < 5 then makeSdelayInitInstr structvar argList loc lv else makeSdelayInitInstr structvar (L.tl argList) loc lv
    |Call(lv,Lval(Var vi,_),argList,loc) when (vi.vname = "fdelay") -> if L.length argList < 5 then makeFdelayInitInstr structvar argList loc ret_jmp (integer signo) tpstructvar lv else makeFdelayInitInstr structvar (L.tl argList) loc ret_jmp (integer signo) tpstructvar  lv
	|Call(lv ,Lval(Var vi,_), argList, loc) when (vi.vname = "gettime") -> makegettimeInstr lv structvar argList loc
	(*|Call(_,LVal(Var vi,_),_,loc) when (vi.vname = "next") -> makeNextGoto loc *)
	|Call(_,Lval(Var vi,_),argList,_) when (isFunTask vi) ->
                                                        let pthread_id_str = "pthread_t" in
                                                        let pthread_id_type = findTypeinfo filename pthread_id_str in
                                                        let pthread_var = makeLocalVar fdec ("t_"^string_of_int(List.length !all_threads)) (TNamed(pthread_id_type, [])) in
                                                        let intr =
                                                            makePthreadCreateInstr
                                                            pthread_var vi
                                                            argList locUnknown
                                                            fdec in
                                                        all_threads:= pthread_var :: (!all_threads); [intr]
	(*|Call(_,Lval(Var vi,_),argList,loc) when (vi.vname = "cread") -> all_read:= fdec.svar.vname ::  (!all_read); [i] *)

    |_ -> [i] in
        ChangeDoChildrenPost([i], action)

(*
	method vblock b =
	if List.length b.bstmts <> 0 then
	let action  b  =
	let tl = (List.tl b.bstmts) in
	let s  = (List.hd b.bstmts) in
	begin
	(*let replaceBlockWithFdelay (List.hd b.bstmts) (List.tl b.bstmts) b data structvar tpstructvar timervar ret_jmp data sigvar*)
		match s.skind with
		|Instr il when il <> [] ->
                         if (List.exists instrTimingPointAftr il) && (checkFirmSuccs data s) then
                         (*let label_stmt = mkStmt (Instr []) in
                         label_stmt.labels <- [Label(string_to_int s.sid,locUnknown,false)] ;*)
                         let tname = E.log "out here fdelay" in
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
*)

	method vstmt s =
	let action s =
	match s.skind with
	|Instr il when (il <> []) && (List.exists instrTimingPointAftr il) && (checkFirmSuccs data s)  -> begin
                         (*if (List.exists instrTimingPointAftr il) && (checkFirmSuccs data s) then *)
                         (*let label_stmt = mkStmt (Instr []) in
                         label_stmt.labels <- [Label(string_to_int s.sid,locUnknown,false)] ;*)
                         let firmSuccInst = retFirmSucc s data in
                         let intr = getInstr firmSuccInst in
                         let addthisTo = maketimerfdelayStmt structvar intr tpstructvar timervar ret_jmp firmSuccInst in
			 s.skind <- Block (mkBlock ((mkStmtOneInstr (List.find instrTimingPointAftr il)) :: addthisTo)); s
			end
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
	(*|Block b -> let hstm = List.hd b.bstmts in
		    (match hstm.skind with
	       	      |Instr (il) ->
			if (List.length il = 1 &&  instrTimingPoint (List.hd il)) && (instrTimingPoint (List.hd il)) then
			let label_name = "_"^string_of_int(s.sid) in
			let label_no =  (get_label_no (List.hd il) )in
			(*let label_no =  getvaridStmt s in*)
			let label_stmt = mkStmt (Instr []) in
                		label_stmt.labels <- [Label(label_name,locUnknown,false)]; (*E.log "s.sid  %d \n" s.sid;*) HT.add labelHash label_no label_stmt;
			let changStmTo = List.append [mkStmt s.skind] [label_stmt] in
			let changStmTo1 = List.append changStmTo (List.tl b.bstmts) in
			let block = mkBlock  changStmTo1 in
                	s.skind <- Block block ;
                	s
                	else
                	s
		     |_ -> s)	*)
	 |Instr (il) ->
			if (List.length il = 1 &&  instrTimingPoint (List.hd il)) && (instrTimingPoint (List.hd il)) then
			let label_name = "_"^string_of_int(s.sid) in
			let label_no =  (get_label_no (List.hd il) )in
			(*let label_no =  getvaridStmt s in*)
			let label_stmt = mkStmt (Instr []) in
                		label_stmt.labels <- [Label(label_name,locUnknown,false)]; (*E.log "s.sid  %d \n" s.sid;*) HT.add labelHash label_no label_stmt;
			let changStmTo = List.append   [mkStmt s.skind] [label_stmt] in
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



class addpolicyDetailFunc filename = object(self)
	inherit nopCilVisitor
        method vfunc (fdec : fundec) =
		let runtime = makeLocalVar fdec "runtime" intType in
		let deadline = makeLocalVar fdec "deadline" intType in
		let period = makeLocalVar fdec "period" intType in
		let priority = makeLocalVar fdec "priority" intType in
		let policy = makeLocalVar fdec "policy" intType in
		let taskid =  makeLocalVar fdec "taskid" charPtrType in
		let setschedvar = makeLocalVar fdec "setschedvar" intType in
		let list_dl_var = findGlobalVar filename.globals "list_dl" in
		let list_pr_var = findGlobalVar filename.globals "list_pr" in
		let data =  checkTPSucc fdec filename  in
		let pd = new policydetail filename data runtime deadline period priority policy list_dl_var list_pr_var setschedvar in
		fdec.sbody <- visitCilBlock pd fdec.sbody;
		(match fdec.svar.vtype with
                        | TFun(rt,_,_,attr) (*when (isTaskType rt)*)-> let set_taskid = mkStmtOneInstr (Set(var taskid, mkString fdec.svar.vname, locUnknown)) in
								   let setschedvar_init = mkStmtOneInstr (Set(var setschedvar, Cil.zero, locUnknown)) in
								   (*let initialsdelay = mkStmtOneInstr
                                    * (Call(None, v2e
                                    * sdelayfuns.start_timer_init, [(Cil.integer
                                    * (-1404));(Cil.integer (-1404)); Cil.zero],
                                    * locUnknown)) in*)
								   fdec.sbody.bstmts <- List.append [set_taskid; setschedvar_init] fdec.sbody.bstmts; ()
                        | _ ->	()
		);ChangeTo(fdec)
end


class populate_pr_dl filename = object(self)
	inherit nopCilVisitor

	method vfunc (fdec : fundec) =
	if fdec.svar.vname = "populatelist" then
	fdec.sbody <- mkBlock ( mkStmt (Instr(List.rev (!lstinstpolicy))) :: fdec.sbody.bstmts);
	 ChangeTo(fdec)

end
class mergeDelays filename = object(self)
	inherit nopCilVisitor

	method vfunc (fdec : fundec) =
	let md = new merger filename fdec in
	fdec.sbody <- visitCilBlock md fdec.sbody; ChangeTo(fdec)

end

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
		let init_start = makeSdelayEndInstr fdec structvar ftimer tpstructvar signo in
		let populate_instr = (mkStmtOneInstr (Call(None, v2e sdelayfuns.compute_priority, [integer (!policyindex);], locUnknown))) in
		let data =  checkTPSucc fdec filename  in
		let y = checkAvailOfStmt fdec in
	(*	let policydetail = new addPolicydetail filename data runtime deadline period priority in
		fdec.sbody <- visitCilBlock policydetail fdec.sbody;
		let addl = new  addLabelStmt filename in
                fdec.sbody <- visitCilBlock addl  fdec.sbody ; *)
		(*let y' = isErrorFree filename in*)
		let modifysdelay = new sdelayReportAdder filename fdec structvar tpstructvar ftimer rt_jmp data fname org_sig signo in
		fdec.sbody <- visitCilBlock modifysdelay fdec.sbody;
		fdec.sbody.bstmts <- List.append init_start fdec.sbody.bstmts;
		fdec.sbody.bstmts <- addPthreadJoin fdec fdec.sbody.bstmts ;
		(*if fdec.svar.vname = "main" then
		fdec.sbody.bstmts <- populate_instr :: fdec.sbody.bstmts;*)
                ChangeTo(fdec)

end

class profileTask filename = object(self)
    inherit nopCilVisitor
    method vfunc (fdec : fundec) =
        let vi = fdec.svar in
        let arglist = fdec.sformals in
        let id_var = makeTempVar fdec intType in
        let count_var = makeTempVar fdec intType in
        let timestruct = findCompinfo filename "timespec" in
        let itime = makeLocalVar fdec "ktctime" (TComp(timestruct,[])) in
        (*init file instr*)
        let logname = findCompinfo filename "_IO_FILE" in
        let logname_var = makeLocalVar fdec ("ktclog")
        (TPtr(TComp(logname,[]), [])) in
        let log_init_instr = makeLogTraceInit (var logname_var) (mkString
        vi.vname)  locUnknown in
        (*let start_time_var = findLocalVar fdec.slocals ("start_time") in
        let itime_init_start_time = Set((Var(itime), NoOffset), v2e
        start_time_var, locUnknown) in*)
        (*print ps*)
        let last_arrival_var = makeLocalVar fdec "ktcatime" ulongType in
        let trace_init_instr = makeLogTraceTask ((v2e logname_var)) (mkAddrOf (var
        last_arrival_var)) (v2e itime) locUnknown  in
        (*let offset_from_caller = if ((isFunTaskName vi.vname) & (vi.vname <> "main") &
        (List.length arglist <> 0)) then (Set((Var(last_arrival_var),
        NoOffset),  StartOf(Mem(v2e (List.hd arglist)), NoOffset), locUnknown)) else (Set((Var(last_arrival_var),
        NoOffset), Cil.zero, locUnknown)) in*)
        let offset_from_caller = (Set((Var(last_arrival_var),
        NoOffset), Cil.zero, locUnknown)) in
        (*print release*)
        let execution_start_var = makeLocalVar fdec "ktcstime"
        (TComp(timestruct,[])) in
        (*let trace_release_instr = makeLogTraceRelease (v2e logname_var) (v2e
        last_arrival_var) (v2e itime) (mkAddrOf (var execution_start_var))
        locUnknown in *)
        let trace_end_instr = makeLogTraceExecution (v2e logname_var) (v2e
        execution_start_var) locUnknown in
        let return_stmnt_in_func = List.hd (List.rev fdec.sbody.bstmts) in
        let add_end_instr_without_return = (mkStmtOneInstr trace_end_instr) ::
             (List.tl (List.rev fdec.sbody.bstmts)) in
        let add_end_instr_with_return = return_stmnt_in_func ::
             (add_end_instr_without_return) in
        let modifyprofile = new profilingAdder filename logname_var
        last_arrival_var execution_start_var itime fdec id_var count_var in
        if (isFunTaskName vi.vname) then
		fdec.sbody <- visitCilBlock modifyprofile fdec.sbody;
        let id_init = Set((Var(id_var),NoOffset), Cil.zero, locUnknown) in
        let count_init = Set((Var(count_var),NoOffset), Cil.zero, locUnknown) in
        let prepend_statement = mkStmt (Instr([id_init; count_init;
        offset_from_caller; log_init_instr; trace_init_instr])) in
        if (vi.vname <> "main") then
            fdec.sbody.bstmts <- List.rev add_end_instr_with_return;
        if(vi.vname <> "main") then
            fdec.sbody.bstmts <- prepend_statement :: (fdec.sbody.bstmts);
    ChangeTo(fdec)
end

class tfgMinusForTask filename = object(self)
    inherit nopCilVisitor
    method vfunc (fdec: fundec) =
        let _ = jnodeslist := [] in
        let _ = if (isFunTask fdec.svar) then
        ((*let _ = E.log "tfgMinusForTask %s \n" fdec.svar.vname in*)
        let tfgjson = new tfgMinus fdec in
        let jnodes = (`Assoc(["nodes", `List(!jnodeslist)])) in
        let _ = fdec.sbody <- visitCilBlock tfgjson fdec.sbody in
        let _ = offsetvar := 0 in
        (*let _ = E.log "len of jnodeslist %d \n" (List.length !jnodeslist) in*)
        let jedges = completeJsonEdges !jnodeslist fdec.svar.vname in
        let jtask = `Assoc([(fdec.svar.vname,`Assoc([("vertices", `List(!jnodeslist));
            ("edges", `List(jedges))]))]) in
       (* let _ = to_channel stdout jtask in *)
        (jtasklist := jtask :: !jtasklist);
        (*(if (fdec.svar.vname = "main") then (Yojson.Safe.to_channel stdout)
        (`List(!jtasklist)))*);
        (if (fdec.svar.vname = "main") then (Yojson.Safe.to_file
        "tfg_minus.json")
        (`List(!jtasklist)));  (Csv.save "input.csv" !csvlist);
        (Csv.save
        "ijob.csv" !joblist);
        (if (fdec.svar.vname = "main") then ( findHyperperiod !csvlist
        !abortlist !joblist)); (Csv.save "input.csv" !csvlist); (Csv.save
        "abort.csv" !abortlist);
        ()) in

       (* let _ = (if (List.length !jnodeslist > 0) then
            to_channel stdout (`Assoc([("vertices", `List(!jnodeslist));
            ("edges", `List(jedges))]))) in *)
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
        |If(CastE(t,e),b,_,_) when isReadType t -> if(isSimp (fst (getExpNameR e))) then
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
        |If(CastE(t,e),b,_,_) when isInitType t ->(*E.log "INIT";*)if (isFifo (fst (getExpNameW e)) !fifovarlst) then
						   let channame = fst (getExpNameW e) in
						   let fifothrdqu = findGlobalVar f.globals channame in
						   let init_call = Call(None, v2e sdelayfuns.fifo_init, [((mkAddrOf (var fifothrdqu)));], locUnknown) in
						   let slist = [mkStmtOneInstr init_call] in
						   let nb = mkBlock slist in
                                                    s.skind <- Block nb; s
						   else
					           s
        |If(CastE(t,e),b,_,_) when isWriteType t ->(*E.log "WRITES";*)if (isFifo (fst (getExpNameW e)) !fifovarlst) then
						   let channame = fst (getExpNameW e) in
						   let fifothrdqu = findGlobalVar f.globals channame in
						   let fifochanlist = findGlobalVar f.globals (channame^"ktclist") in
						   let fifocount = findGlobalVar f.globals (channame^"ktccount") in
						   let fifotail= findGlobalVar f.globals (channame^"ktctail") in
						   let writeVal = snd (getExpNameW e) in
						   let witeLV = getLValChan writeVal in
					           let write_call = Call(None, v2e sdelayfuns.fifo_write, [mkAddrOf (var fifothrdqu);mkAddrOf (var fifochanlist);mkAddrOf (var fifocount);mkAddrOf (var fifotail); AddrOf(witeLV); SizeOfE(Lval(witeLV))], locUnknown) in
                                                   let slist = [mkStmtOneInstr write_call] in
                                                   let nb = mkBlock slist in
                                                    s.skind <- Block nb; s
                                                   else
                                                   s

						   (*
                                                    let fifovar = HT.find fifoChanSet (fst (getExpNameW e)) in
						   let writeVal = snd (getExpNameW e) in
                                                   let write_call = Call(None, v2e sdelayfuns.fifo_write, [((mkAddrOf (var fifovar))); writeVal;], locUnknown) in
                                                   let slist = [mkStmtOneInstr write_call] in
                                                   let nb = mkBlock slist in
                                                    s.skind <- Block nb; s
                                                   else
                                                   s *)
       |If(CastE(t,e),b,_,_) when isReadType t ->  (*E.log "READ";*)if (isFifo (fst (getExpNameR e)) !fifovarlst) then
						   let tpvar = findLocalVar fdec.slocals ("tp") in
						   let waitingOffset = match tpvar.vtype with
		      							| TComp (cinfo, _) -> Field (getCompField cinfo "waiting", NoOffset) in
  						   let waitingConditionInstr = Set((Var tpvar, waitingOffset), Cil.one, locUnknown) in
						   let channame = (fst (getExpNameR e)) in
						   let fifothrdqu = findGlobalVar f.globals channame in
						   let fifochanlist = findGlobalVar f.globals (channame^"ktclist") in
						   let fifocount = findGlobalVar f.globals (channame^"ktccount") in
						   let fifotail= findGlobalVar f.globals (channame^"ktctail") in
						   let readVar = snd (getExpNameR e) in
						   let readLV = getLValChan readVar in
					           let read_call = Call(None, v2e sdelayfuns.fifo_read, [mkAddrOf (var fifothrdqu);mkAddrOf (var fifochanlist);mkAddrOf (var fifocount);mkAddrOf (var fifotail); AddrOf(readLV); (SizeOfE(Lval(readLV))); Cil.zero ], locUnknown) in
					           let slist = [mkStmtOneInstr waitingConditionInstr;  mkStmtOneInstr read_call] in
                                                   let nb = mkBlock slist in
                                                    s.skind <- Block nb; (*E.log "END";*) s
                                                   else
                                                   s



						   (*
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
                                                   s *)


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


let addpolicyDetail f =
        let vis = new addpolicyDetailFunc f in
        visitCilFile vis f


let tfgMinusGeneration f =
    let vis = new tfgMinusForTask f in
    visitCilFile vis f

let profileTransformation f =
    let vis = new profileTask f in
    visitCilFile vis f

let timingConstructsTransformatn f =
         let fname = "sdelay" in
        let vis = new sdelayFunc f fname 0 in
        visitCilFile vis f

let fillgloballist_pr_dl f =
	let vis = new populate_pr_dl f in
	visitCilFile vis f

let mergeTimingPoints f =
	let vis = new mergeDelays f in
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
initSdelayFunctions f; (*mergeTimingPoints f ;*) timing_basic_block f; addpolicyDetail f; timing_basic_block f;  Cfg.clearFileCFG f; Cfg.computeFileCFG f;  addLabel f;  Cfg.clearFileCFG f; concurrencyA f;
(*List.iter (fun (a,b) -> E.log "(%s %d)" a b) !all_task; *) chanReaderWriterAnalysis f;
    tfgMinusGeneration f; profileTransformation f; timingConstructsTransformatn f; fifoAnalysi f;(*concurrencyConstructsTransformatn f ;*) fillgloballist_pr_dl f;  ()



(*
let sdelay (f : file) : unit =
  initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
 *)

