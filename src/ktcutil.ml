(* This file extends tututil.ml from the CIL Template project by Zach Anderson *) 

open Cil
open Pretty

module E = Errormsg
module S = Str
module H = Hashtbl
module U = Util
module IH = Inthash
module UD = Usedef

module DF = Dataflow


let debug = false

let debugBF = ref false
module SM = Map.Make(struct
  type t = string
  let compare = Pervasives.compare
end)


let i2s (i : instr) : stmt = mkStmt(Instr [i])

let v2e (v : varinfo) : exp = Lval(var v)

let (|>) (a : 'a) (f : 'a -> 'b) : 'b = f a

let fst4 (a,_,_,_) = a
let snd4 (_,b,_,_) = b
let thd4 (_,_,c,_) = c
let fur4 (_,_,_,d) = d

let fst3 (a,_,_) = a
let snd3 (_,b,_) = b
let thd3 (_,_,c) = c

let fst23 (f,s,_) = (f,s)
let snd23 (_,s,t) = (s,t)

let fst24 (f,s,_,_) = (f,s)

let tuplemap (f : 'a -> 'b) ((a,b) : ('a * 'a)) : ('b * 'b) = (f a, f b)

let triplemap (f : 'a -> 'b) ((a,b,c) : ('a * 'a * 'a)) : ('b * 'b * 'b) =
  (f a, f b, f c)

let getVarFromExp expv =
	match expv with
	| Lval(Var vi, _) -> vi
	|_ -> raise(Failure "Exp not variable")

let forceOption (ao : 'a option) : 'a =
  match ao with
  | Some a -> a
  | None -> raise(Failure "forceOption")

let remove_elt e l =
  let rec go l acc = match l with
    | [] -> List.rev acc
    | x::xs when e = x -> go xs acc
    | x::xs -> go xs (x::acc)
  in go l []

let remove_duplicates_in_list l =
  let rec go l acc = match l with
    | [] -> List.rev acc
    | x :: xs -> go (remove_elt x xs) (x::acc)
  in go l []


let list_of_hash (sih : ('a, 'b) Hashtbl.t) : ('a * 'b) list =
	Hashtbl.fold (fun a b l -> (a,b) :: l) sih []

let list_init (len : int) (f : int -> 'a) : 'a list =
	let rec helper l f r =
		if l < 0 then r
		else helper (l - 1) f ((f l) :: r)
	in
	helper (len - 1) f []

let split ?(re : string = "[ \t]+") (line : string) : string list =
  S.split (S.regexp re) line


let unrollType2dArray vtype =
	match vtype with 
	| TArray(TArray(t,_,_),_,_) -> t 
	| _ -> E.s (E.bug "Not 2-D matrix"); vtype

let onlyFunctions (fn : fundec -> location -> unit) (g : global) : unit = 
  match g with
  | GFun(f, loc) -> fn f loc
  | _ -> ()

let function_elements (fe : exp) : typ * (string * typ * attributes) list =
  match typeOf fe with
  | TFun(rt, Some stal, _, _) -> rt, stal
  | TFun(rt, None,      _, _) -> rt, []
  | _ -> E.s(E.bug "Expected function expression")

let fieldinfo_of_name (t: typ) (fn: string) : fieldinfo =
	match unrollType t with
	| TComp(ci, _) -> begin
		try List.find (fun fi -> fi.fname = fn) ci.cfields
		with Not_found ->
			E.s (E.error "%a: Field %s not in comp %s"
				d_loc (!currentLoc) fn ci.cname)
	end
	| _ ->
		E.s (E.error "%a: Base type not a comp: %a"
			d_loc (!currentLoc) d_type t)

let force_block (s : stmt) : block =
  match s.skind with
  | Block b -> b
  | _ -> E.s(E.bug "Expected block")

let list_equal (eq : 'a -> 'a -> bool) (l1 : 'a list) (l2 : 'a list) : bool =
  let rec helper b l1 l2 =
    if not b then false else
    match l1, l2 with
    | e1 :: rst1, e2 :: rst2 ->
      helper (eq e1 e2) rst1 rst2
    | [], [] -> true
    | _, _ -> false
  in
  helper true l1 l2

let list_take (len : int) (l : 'a list) : 'a list =
  let rec helper n l res =
    match l with
    | [] -> List.rev res
    | _ :: _ when n = 0 -> List.rev res
    | x :: rst -> helper (n - 1) rst (x :: res)
  in
  helper len l []

let list_union (l1 : 'a list) (l2 : 'a list) : 'a list =
  List.fold_left (fun l a2 ->
    if not(List.mem a2 l) then a2 :: l else l
  ) l1 l2

let sm_find_all (sm : 'a SM.t) (sl : string list) : 'a list =
  List.map (fun s -> SM.find s sm) sl

let sargs (f : 'b -> 'a -> 'c) (x : 'a) (y : 'b) : 'c = f y x

let list_of_growarray (ga : 'a GrowArray.t) : 'a list =
  GrowArray.fold_right (fun x l -> x :: l) ga []

let array_of_growarray (ga : 'a GrowArray.t) : 'a array =
  Array.init (GrowArray.max_init_index ga + 1) (GrowArray.get ga)

let array_sort_result (c : 'a -> 'a -> int) (a : 'a array) : 'a array =
  Array.sort c a;
  a

let array_filter (f : 'a -> bool) (a : 'a array) : 'a array =
  a |> Array.to_list |> List.filter f |> Array.of_list

let array_bin_search (c : 'a -> 'a -> int) (x : 'a) (a : 'a array) : int list =
  if Array.length a = 0 then raise(Invalid_argument "array_bin_search") else
  let rec helper (lo : int) (hi : int) : int list =
    if lo >= hi then begin
      match c a.(hi) x with
      | 0            -> [hi]
      | n when n > 0 -> [max 0 hi-1; hi]
      | _            -> [hi        ; min (hi+1) (Array.length a - 1)]
    end else begin
      let mid = (lo + hi) / 2 in
      match c a.(mid) x with
      | 0            -> [mid]
      | n when n > 0 -> helper lo (mid - 1)
      | _            -> helper (mid + 1) hi
    end
  in
  helper 0 (Array.length a - 1)

type comment = Cabs.cabsloc * string * bool

let cabsloc_of_cilloc (l : location) : Cabs.cabsloc =
  {Cabs.lineno = l.line; Cabs.filename = l.file; Cabs.byteno = l.byte; Cabs.ident = 0;}

let cilloc_of_cabsloc (l :Cabs.cabsloc) : location =
  {line = l.Cabs.lineno; file = l.Cabs.filename; byte = l.Cabs.byteno;}

let comment_of_cilloc (l : location) : comment =
  (cabsloc_of_cilloc l, "", false)

let cabsloc_compare (l1 : Cabs.cabsloc) (l2 : Cabs.cabsloc) : int =
  compareLoc (cilloc_of_cabsloc l1) (cilloc_of_cabsloc l2)

let comment_compare (c1 : comment) (c2 : comment) : int =
  cabsloc_compare (fst3 c1) (fst3 c2)

let rec findType (gl : global list) (typname : string) : typ =
  match gl with
  | [] -> E.s (E.error "Type not found: %s" typname)
  | GType(ti,_) :: _        when ti.tname = typname -> TNamed(ti,[])
  | GCompTag(ci,_) :: _     when ci.cname = typname -> TComp(ci,[])
  | GCompTagDecl(ci,_) :: _ when ci.cname = typname -> TComp(ci,[])
  | GEnumTag(ei,_) :: _     when ei.ename = typname -> TEnum(ei,[])
  | GEnumTagDecl(ei,_) :: _ when ei.ename = typname -> TEnum(ei,[])
  | _ :: rst -> findType rst typname

let rec findFunction (gl : global list) (fname : string) : fundec =
    match gl with
    | [] -> raise(Failure "Function not found")
    | GFun(fd,_) :: _ when fd.svar.vname = fname -> fd
    | _ :: rst -> findFunction rst fname

(*let rec findCompinfo (gl : global list) (ciname : string) : compinfo =
	match gl with
	| [] -> raise(Failure "Compinfo not found")
	| GCompTag(ci, _) :: _ when ci.cname = ciname -> ci
	| GCompTagDecl(ci, _) :: _ when ci.cname = ciname -> ci
	| _ :: rst -> findCompinfo rst ciname
*)

let findLocalVar (sl : varinfo list) (varname : string) : varinfo =
	List.find (fun vi -> if vi.vname = varname then true else false) sl 

let rec findGlobalVar (gl : global list) (varname : string) : varinfo =
  match gl with
  | [] -> E.s (E.error "Global not found: %s" varname)
  | GVarDecl(vi, _) :: _ when vi.vname = varname -> vi
  | GVar(vi, _, _) :: _ when vi.vname = varname -> vi
  | _ :: rst -> findGlobalVar rst varname

let mallocType (f : file) : typ =
  let size_t = findType f.globals "size_t" in
  TFun(voidPtrType, Some ["s",size_t,[]], false, [])

let iterCompound ~(implicit : bool)
                 ~(doinit : offset -> init -> typ -> unit -> unit)
                 ~(ct : typ) ~(initl : (offset * init) list)
                 : unit
  =
  foldLeftCompound ~implicit ~doinit ~ct ~initl ~acc:()

(*Functions Specific to KTC *)

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



(* For each statement we maintain a set of variables that ware available*)
module VS = UD.VS

(* Customization  module for dominators *)
module AV = struct
        let name = "avail"
        let debug = ref debug
        type t = VS.t

        let stmtStartData = IH.create 32

        let copy (avl : t) = avl

        let pretty () (avl: t) =
                dprintf "{%a}"
                        (docList (fun v -> dprintf "%s" v.vname)) (VS.elements avl)

        let computeFirstPredecessor (s: stmt) (avl: VS.t) : VS.t =
                let u, d = UD.computeUseDefStmtKind s.skind in
                VS.union d avl

        let combinePredecessors (s: stmt) ~(old: VS.t) (avl: VS.t) : VS.t option =
        let u, d = UD.computeUseDefStmtKind s.skind in
        let d' = VS.union d avl in 
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

let printSucc s tsucc =
	E.log "\n\t%d -> %d" s.sid tsucc.sid


let printSuccToFile oc s  tsucc  =
        Printf.fprintf oc "\n\t%d -> %d" s.sid tsucc.sid 

let printAvailCFG s tsucc  =
	match s.skind with 
	| Instr il when List.length il = 1->  begin
			match List.hd il with 
			|Call(_, Lval(Var vi, _),_,_) when vi.vname = "fdelay" -> E.log "\n%d [label= \"%s\"]" s.sid vi.vname; List.iter (printSucc s) tsucc 
        		|Call(_, Lval(Var vi, _),_,_) when vi.vname = "sdelay" -> E.log "\n%d [label= \"%s\"]" s.sid vi.vname; List.iter (printSucc s) tsucc
			|_ -> E.log ""
				end
        |_ -> E.log ""

let printTimeCFG oc s tsucc  =
	(*let h = fprintf oc "diagraph Timed_CFG {" in *) 
        match s.skind with
        | Instr il when List.length il = 1->   
                        begin 
			match List.hd il with
                        |Call(_, Lval(Var vi, _),_,_) when vi.vname = "fdelay" -> Printf.fprintf oc "\n%d [label= \"%s\"]"  s.sid vi.vname; List.iter (printSuccToFile oc s) tsucc   
                        |Call(_, Lval(Var vi, _),_,_) when vi.vname = "sdelay" -> Printf.fprintf oc "\n%d [label= \"%s\"]"  s.sid vi.vname ; List.iter (printSuccToFile oc s) tsucc 
                        |_ ->  Printf.fprintf oc "" 
                        end        
        |_ -> Printf.fprintf oc ""

let printAvail s =
        match s.skind with
        | Instr il when List.length il = 1-> begin
                        match List.hd il with
                        |Call(_, Lval(Var vi, _),_,_) -> E.log "Available for %s: %a\n" vi.vname
                        |_ -> E.log "Available for %d: %a\n" s.sid
                        end
        |_ -> E.log "Available for %d: %a\n" s.sid



let computeAvail ?(doCFG:bool=false) (f: fundec)  =
  (* We must prepare the CFG info first *)
	let ch = open_out "timed_graph.dot" in 
	let y = 
        if doCFG then begin
                 prepareCFG f;
                computeCFGInfo f false
        end;
        IH.clear AV.stmtStartData;
         match f.sbody.bstmts with
        | [] -> () (* function has no body *)
        | start :: _ -> begin
		let u, d = UD.computeUseDefStmtKind start.skind in
                (* We start with only the start block *)
                IH.add AV.stmtStartData start.sid  d;  Avail.compute [start];
                 (* Dump the dominators information *)
	
           List.iter
		
             (fun s ->
               let savail = getStmtAvail AV.stmtStartData s in
		ignore (printAvail s
		 (*ignore (E.log "Available for %d: %a\n" s.sid*)
                         AV.pretty (savail))
             )f.sallstmts
	
	   end
	in 
	  close_out ch

let isFirm (i : instr) : bool =
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "fdelay") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "sdelay")  ->  false
    | _ -> false

let isTimingPoint (i : instr) : bool =
   match i with
    | Call (_, Lval (Var vf, _), _, _) when (vf.vname = "fdelay") -> true
    | Call (_, Lval(Var vf,_), _, _) when (vf.vname = "sdelay")  -> true
    | _ -> false

let addVarDelay il =
	let ret = VS.empty in 
	match il with 
	 | Call (_, Lval (Var vf, _), _, _) -> VS.add vf ret  
	 | _ -> ret 
 
let computeAvailOfStmt data s il =
  let savail = getStmtAvail data s in
	let vardelay = addVarDelay il in
        let u, d  =  UD.computeUseDefInstr il in
	let suse = VS.diff u vardelay in
	   if VS.is_empty suse then begin 
               true 
		end
        else
	    begin
               VS.subset suse savail
	    end

let checkAvail data s il =
	if not(computeAvailOfStmt data s il) then begin 
			let loc = get_stmtLoc s.skind in
                        (Printf.eprintf "%s:%d:" loc.file loc.line)  ; E.s (E.error "undefined variable in  %a" dn_instr il)
end

let checkAvailOfStmt f  = 
	IH.clear AV.stmtStartData;
         match f.sbody.bstmts with
        | [] -> () (* function has no body *)
        | start :: _ -> begin
                let u, d = UD.computeUseDefStmtKind start.skind in
                (* We start with only the start block *)
                IH.add AV.stmtStartData start.sid  d;  Avail.compute [start];
                 (* Dump the dominators information *)
(*	List.iter
	(fun s ->
               let savail = getStmtAvail AV.stmtStartData s in
                ignore (printAvail s
                 (*ignore (E.log "Available for %d: %a\n" s.sid*)
                         AV.pretty (savail))
             )f.sallstmts ; *)
	  List.iter

             (fun s -> match s.skind with 
			| Instr il -> if (List.length il = 1 &&  isTimingPoint (List.hd il)) then
					checkAvail AV.stmtStartData s (List.hd il)
				 
			| _ -> ()
             )f.sallstmts
           end

		 

module TS = Set.Make(struct 
                        type t = Cil.stmt
                        let compare v1 v2 = Pervasives.compare v1.sid v2.sid
                     end)

let addSucc s = 
	match s.skind with 
	|Instr il -> if (List.length il = 1 &&  isTimingPoint (List.hd il)) then 
				TS.singleton s
		     else
			 	TS.empty
	|_ -> TS.empty

		(*	
let tsuccStm slist tsucc=
	match slist with 
	|h::t -> begin
		 if (addSucc h)  then
		  	 
		end
	|_ -> ()

*)

module TPSucc = struct
  let name = "timing-point-succ"
  let debug = debugBF
  type t = TS.t


  let pretty () (tsucc: t) = 
    dprintf "{%a}" 
      (docList (fun s -> dprintf "%d" s.sid))
      (TS.elements tsucc)
(*
  let pretty () (tsucc: t) =
      dprintf "%a "
      (dstmt ()  (fun s -> dprintf "%d" s.sid)) tsucc
 *)
  let stmtStartData = IH.create 64

  let funcExitData = TS.empty

  let combineStmtStartData (stm:stmt) ~(old:t) (now:t) =
    if ((not(TS.compare old now = 0)) && TS.cardinal old = 0)
    then Some(TS.union old now)
    else None

  let combineSuccessors t1 t2 = TS.union t1 t2

  let doStmt stmt = DF.Default  
		
  let doInstr i vs = DF.Default

  let filterStmt stm1 stm2 = true

end

module TSucc = DF.BackwardsDataFlow(TPSucc)

let all_stmts = ref []


class nullAdderClass data = object(self)
  inherit nopCilVisitor

  method vstmt s =
    all_stmts := s :: (!all_stmts); begin
    match s.skind with  
   |Return _ -> IH.add data s.sid TS.empty
   |_ ->   
    let addAsSucc = if List.length s.succs > 0  then 
			List.map addSucc s.succs 
		    else
			[TS.empty] 
		in
   let addSet = if (List.for_all (TS.is_empty) (addAsSucc)) then 
			TS.empty
		else 
			List.fold_left (TS.union) (TS.empty) (addAsSucc) in
                IH.add data s.sid  addSet
	end;
	DoChildren

end

let null_adder fdec data =
  all_stmts := []; ignore(visitCilFunction (new nullAdderClass data) fdec);
  !all_stmts 


let getStmtTPSucc (data: TS.t IH.t) (s: stmt) : TS.t =
  try IH.find data s.sid
  with Not_found -> TS.empty (* Not reachable *)

let retTimingPoint s =
	match s.skind with
	| Instr il ->  begin
                        if List.length il = 1  && (isTimingPoint (List.hd il)) then
                                true
                        else
                                false
                      end
        |_ -> false
let retFirm s =
	match s.skind with
	| Instr il ->  begin
			if List.length il = 1  && (isFirm (List.hd il)) then
				true
			else 
				false 
		      end
	|_ -> false 
	

let checkSuccs (data: TS.t IH.t) (s: stmt) =
	let tsuccsofs = getStmtTPSucc data s in
		let firmsucc = TS.filter retFirm tsuccsofs  in
			if TS.cardinal firmsucc > 1 then begin
				let loc = get_stmtLoc s.skind in
				  (Printf.eprintf "%s:%d:" loc.file loc.line)  ; E.s (E.error "conflicting firm timing point for %a" dn_stmt s) 
		end
let checkFirmSuccs (data: TS.t IH.t) (s: stmt) = 
        let tsuccsofs = getStmtTPSucc data s in
                let firmsucc = TS.filter retFirm tsuccsofs  in
                        if TS.cardinal firmsucc > 0 then
				true
			else
			        false
let retTimingPointSucc s data =
	let tsuccsofs = getStmtTPSucc data s in
	let succSet = TS.filter retTimingPoint tsuccsofs in
	let succList = TS.elements succSet in
	let intrfirmSucc = if List.length succList = 1 then List.hd succList
                           else
			let loc = get_stmtLoc s.skind in
                        (Printf.eprintf "%s:%d:" loc.file loc.line); E.s (E.error "conflicting target destination for next")  in
                intrfirmSucc


let  retFirmSucc s data =
	let tsuccsofs = getStmtTPSucc data s in
        let firmsucc = TS.filter retFirm tsuccsofs  in
	let firmsuccList = TS.elements firmsucc in
	let intrfirmSucc = if List.length firmsuccList = 1 then List.hd firmsuccList
			   else 
			dummyStmt in
		intrfirmSucc 
	 		                    
let computeTPSucc ?(doCFG:bool=true) (f: fundec)  = 
        if doCFG then begin
                 prepareCFG f;
                computeCFGInfo f false
        end;
        IH.clear TPSucc.stmtStartData;
	let a = null_adder f TPSucc.stmtStartData in
           TSucc.compute a ;
	
                 (* Dump the dominators information *)
      (*     List.iter

             (fun s ->
               let tsuc = getStmtTPSucc TPSucc.stmtStartData s in
                (*ignore (printAvail s*)
                 ignore (printAvail s
                         TPSucc.pretty (tsuc))
             )f.sallstmts; *)TPSucc.stmtStartData

let checkTPSucc ?(doCFG:bool=true) (f: fundec) fil  =
	let ch = open_out "timed_graph.dot" in
        let h = fprintf ch "digraph Timed_CFG {" in
        if doCFG then begin
		Cfg.clearFileCFG fil;
		Cfg.computeFileCFG fil
		(*
                 prepareCFG f;
                computeCFGInfo f false
		*)
        end;
        IH.clear TPSucc.stmtStartData;
        let a = null_adder f TPSucc.stmtStartData in
           TSucc.compute a ;

                 (* Dump the dominators information *)
           List.iter

             (fun s ->
               let tsuc = getStmtTPSucc TPSucc.stmtStartData s in
			     	(*(printAvailCFG s (TS.elements tsuc));*)
			 	 (printTimeCFG ch s (TS.elements tsuc))
	 )f.sallstmts; fprintf ch "\n}"; close_out ch; 

	List.iter

	(fun s -> match s.skind with
                        | Instr il -> if (List.length il = 1 &&  isTimingPoint (List.hd il)) then
                                        checkSuccs TPSucc.stmtStartData s 

                        | _ -> ()
             )f.sallstmts; TPSucc.stmtStartData 
	
