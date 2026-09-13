# Protected entrypoint; run from Fear-of-Falling after approved adapter handoff.
# No input discovery, source selection, state classification or fallback here.
main<-function() {
 source("R/functions/general_fi_candidate_state.R")
 source("R/functions/general_fi22.R")
 source("R/functions/qc_general_fi22.R")
 root<-normalizePath(Sys.getenv("DATA_ROOT"),mustWork=TRUE)
 repo<-normalizePath("..",mustWork=TRUE)
 inside<-function(p,b) startsWith(p,paste0(b,"/"))
 if(root==repo||inside(root,repo)) fi22_stop()
 readpath<-function(n) {
  p<-normalizePath(Sys.getenv(n),mustWork=TRUE)
  if(!inside(p,root)||inside(p,repo)) fi22_stop()
  p
 }
 paths<-c(source=readpath("FI22_AUTH_SOURCE"),ledger=readpath("FI22_LEDGER"),state_inventory=readpath("FI22_APPROVED_STATE_INVENTORY"))
 sha<-function(p) {
  x<-system2("sha256sum",shQuote(p),stdout=TRUE,stderr=FALSE)
  if(!is.null(attr(x,"status"))||length(x)!=1) fi22_stop()
  h<-strsplit(x," ",fixed=TRUE)[[1]][1]
  if(!grepl("^[a-f0-9]{64}$",h)) fi22_stop()
  h
 }
 expected<-c(source=Sys.getenv("FI22_SOURCE_SHA256"),ledger=Sys.getenv("FI22_LEDGER_SHA256"),state_inventory=Sys.getenv("FI22_STATE_INVENTORY_SHA256"))
 actual<-vapply(paths,sha,"")
 if(!identical(actual,expected)) fi22_stop()
 # Inventory is a separately approved, hash-bound protected adapter product.
 # It must preserve exact index keys, source states and exception provenance.
 b<-readRDS(paths[["state_inventory"]])
 if(!identical(sort(names(b)),sort(c("index","cells","source_sha256","ledger_sha256","study_role_approval","composition","field_map","index_date_field","index_age_field")))) fi22_stop()
 if(!identical(b$source_sha256,expected[["source"]])||!identical(b$ledger_sha256,expected[["ledger"]])||
 !identical(b$composition,FI22_IDS)||!identical(b$study_role_approval,"GENERAL_FI_22_SEVEN_POINT_USER_APPROVAL_2026-09-10")) fi22_stop()
 continuity<-lapply(names(paths),function(n) c(expected[[n]],actual[[n]]));names(continuity)<-names(paths)
 ledger_data<-readRDS(paths[["ledger"]])
 fi22_bind_ledger(ledger_data,b$index,b$cells,b$field_map,b$index_date_field,b$index_age_field)
 result<-fi22_build(b$index,b$cells,b$cells)
 qc<-qc_general_fi22(result,b$index,b$cells,continuity)
 if(!identical(actual,vapply(paths,sha,""))) fi22_stop()
 dest<-Sys.getenv("FI22_PROTECTED_RESULT")
 parent<-normalizePath(dirname(dest),mustWork=TRUE)
 if(!nzchar(dest)||!(parent==root||inside(parent,root))||inside(parent,repo)||file.exists(dest)) fi22_stop()
 old<-Sys.umask("0077");on.exit(Sys.umask(old),add=TRUE)
 audit<-list(continuity=continuity,session_info=capture.output(sessionInfo()),timestamp=format(Sys.time(),tz="UTC"),
 code_sha256=vapply(c("R/functions/general_fi22.R","R/functions/qc_general_fi22.R","R/functions/general_fi_candidate_state.R"),sha,""))
 target<-file.path(parent,basename(dest))
 saveRDS(list(result=result,qc=qc,audit=audit),target)
 Sys.chmod(target,"0600")
 if(!identical(readRDS(target)$result,result)) fi22_stop()
 # Safe fixed receipt only. Aggregate release requires a separate privacy check.
 cat("GENERAL_FI_22_PARTICIPANT_K18_PASS\nPROTECTED_RESULT_ROUNDTRIP_PASS\n")
}
tryCatch(main(),error=function(e) {cat("GENERAL_FI_22_PARTICIPANT_SCORE_IMPLEMENTATION_BLOCKED\n");quit(status=1)})
