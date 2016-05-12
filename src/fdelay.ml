open Cil
open Pretty
open Ktcutil

module E = Errormsg
module L = List


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

type functions = {
  mutable sdelay_init : varinfo;
  mutable sdelay_end  : varinfo;
  mutable fdelay_init :varinfo;
}

let dummyVar = makeVarinfo false "_sdelay_foo" voidType

let sdelayfuns = {
  sdelay_init = dummyVar;
  sdelay_end  = dummyVar;
  fdelay_init = dummyVar;
}



let sdelay_init_str = "ktc_sdelay_init"
let sdelay_end_str   = "ktc_start_time_init"
let fdelay_init_str = "ktc_fdelay_init"

let sdelay_function_names = [
  sdelay_init_str;
  sdelay_end_str;
  fdelay_init_str;
]

let isSdelayFun (name : string) : bool =
  L.mem name sdelay_function_names

let initSdelayFunctions (f : file)  : unit =
  let focf : string -> typ -> varinfo = findOrCreateFunc f in
  let init_type = TFun(intType, Some["intrval", intType, []; "unit", charPtrType, [];],
                     false, [])
  in
  let end_type = TFun(intType, Some["intrval", intType, [];],
                     false, [])
  in
  sdelayfuns.sdelay_init <- focf sdelay_init_str init_type;
  sdelayfuns.sdelay_end <- focf sdelay_end_str   end_type;
  sdelayfuns.fdelay_init <- focf fdelay_init_str init_type


let makeSdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.sdelay_init, [intervl;tunit;s;], loc)]

let makeSdelayEndInstr (structvar : varinfo)   : instr =
  let s =  mkAddrOf((var structvar)) in
Call(None, v2e sdelayfuns.sdelay_end, [s;], locUnknown)

let makeFdelayInitInstr (structvar : varinfo) (argL : exp list) (loc : location) : instr list =
  let time_unit = if (L.length argL) = 1 then mkString "NULL" else L.hd (L.tl argL) in
  let f, l, intervl, tunit, s = mkString loc.file, integer loc.line, L.hd argL, time_unit, mkAddrOf((var structvar)) in
  [Call(None,v2e sdelayfuns.fdelay_init, [intervl;tunit;s;], loc)]



class sdelayReportAdder filename fdec structvar fname  = object(self)
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
	
	
end

class sdelayFunc filename fname = object(self)
        inherit nopCilVisitor

        method vfunc (fdec : fundec) =
		(*Cfg.computeFileCFG filename; *)
		Cfg.clearFileCFG filename;
		Cfg.computeFileCFG filename; 
   		Cfg.printCfgFilename (fdec.svar.vname ^ ".dot") fdec; 
(*		Cfg.cfgFunPrint (fdec.svar.vname^".dot") fdec; *)
               
		let structname = "timespec" in
                let ci = findCompinfo filename structname in
                let structvar = makeLocalVar fdec "start_time" (TComp(ci,[])) in
		let init_start = makeSdelayEndInstr structvar in 
                let modifysdelay = new sdelayReportAdder filename fdec structvar fname  in
                fdec.sbody <- visitCilBlock modifysdelay fdec.sbody;
		fdec.sbody.bstmts <- (mkStmtOneInstr init_start) :: fdec.sbody.bstmts ;
                ChangeTo(fdec)

end

let sdelay (f : file) : unit =
  initSdelayFunctions f; Ciltools.one_instruction_per_statement f ; let fname = "sdelay" in
  let vis = new sdelayFunc f fname in
  visitCilFile vis f
