(* Compute available information for every statement*) 

open Cil
open Pretty
module E = Errormsg
module H = Hashtbl 
module U = Util
module IH = Inthash
module UD = Usedef

module DF = Dataflow

let debug = false

(* For each statement we maintain a set of variables that ware available*)
module VS = UD.VS 

(* Customization module for dominators *)
module AV = struct
	let name = "avail"
	let debug = ref dedug 
	type t = VS.t

	let stmtStartData: t IH.t = IH.create 32

	let copy (avl : t) = avl 

	let pretty () (avl: t) =
		dprintf "{%a}"
			(docList (fun v -> dprintf "%d" v.vid)) (VS.element avl)

	let computeFirstPredecessor (s: stmt) (avl: VS.t) : VS.t =
		let u, d = computeDeepUseDefStmtKind s.skind in 
		VS.add d avl 

	let combinePredecessors (s: stmt) ~(old: VS.t) (avl: VS.t) : VS.t option =
	let u, d = computeDeepUseDefStmtKind s.skind in 
	let d' = VS.add d avl in
	if VS.subset old d' then 
		None
	else
		Some (VS.inter old d')

  	let doInstr (i: instr) (d: VS.t) = DF.Default

  	let doStmt (s: stmt) (d: VS.t) = DF.SDefault
  
 	let doGuard condition _ = DF.GDefault

	let filterStmt _ = true
end


module Avail = DF.ForwardsDataFlow(AV)

let getStmtAvail (data: VS.t IH.t) (s: stmt) : VS.t = 
  try IH.find data s.sid
  with Not_found -> VS.empty (* Not reachable *)

let computeAvail ?(doCFG:bool=true) (f: fundec) : stmt option IH.t = 
  (* We must prepare the CFG info first *)
  	if doCFG then begin
   		 prepareCFG f;
    		computeCFGInfo f false
  	end;
  	IH.clear AV.stmtStartData;
  	(*let availData: stmt option IH.t = IH.create 13 in*)

  	let _ = 
    	 match f.sbody.bstmts with 
      	 [] -> () (* function has no body *)
    	| start :: _ -> begin
        	(* We start with only the start block *)
        	IH.add AV.stmtStartData start.sid (VS.singleton start);  Avail.compute [start];
		 (* Dump the dominators information *)
           List.iter
             (fun s -> 
               let savail = getStmtAvail AV.stmtStartData s in
               if not (VS.mem s savail) then begin
                 (* It can be that the block is not reachable *)
                 if s.preds <> [] then 
                   E.s (E.bug "Statement %d is not in its list of dominators"
                          s.sid);
               end;
               ignore (E.log "Available for %d: %a\n" s.sid
                         AV.pretty (VS.remove s savail)))
             f.sallstmts
