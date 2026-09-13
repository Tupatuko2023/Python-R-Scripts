source("R/functions/general_fi_candidate_state.R")
source("R/functions/general_fi22.R")
source("R/functions/qc_general_fi22.R")
bad<-function(expr) stopifnot(inherits(try(force(expr),silent=TRUE),"try-error"))
# Every approved discrete level tested, including source-defined missing.
for(id in names(fi22_maps())) {
 m<-fi22_maps()[[id]];stopifnot(identical(fi22_map(id,names(m)),unname(m)))
 for(x in c("unknown","e1","Inf","-1")) bad(fi22_map(id,x))
}
stopifnot(identical(fi22_map("RAW-015",as.character(0:4)),c(0,.5,.5,1,NA_real_)))
stopifnot(identical(fi22_map("RAW-012",c("18.49","18.5","24.99","25","29.99","30","E1")),c(1,0,0,.5,.5,1,NA_real_)))
stopifnot(identical(fi22_map("RAW-039",c("0","11.999","12","12,1","E","E1")),c(0,0,1,1,1,NA_real_)))
stopifnot(identical(fi22_map(FI22_BALANCE,c("0","0.001","5","5.001","10","10.001","60")),c(1,.67,.67,.33,.33,0,0)))
# Synthetic population only, never reads protected data.
i<-data.frame(person_ref=paste0("synthetic-",1:479),assessment_ref=paste0("index-",1:479),index_date=as.Date("2020-01-01"),primary_fi_index=TRUE)
v<-i[rep(seq_len(479),each=22),c("person_ref","assessment_ref")]
v$item<-rep(FI22_IDS,479);v$source_state<-"0";v$state<-"SCORED_VALID";v$reason<-"SYNTHETIC_VALID";v$information_date<-as.Date("2020-01-01")
v$source_state[v$item=="RAW-012"]<-"23"
v$source_state[v$item==FI22_BALANCE]<-"15"
# 18,17,0 available; fourth participant has one unresolved value.
m<-c(1:4,23:27,45:66);v$source_state[m]<-NA_character_;v$state[m]<-"SOURCE_DEFINED_MISSING";v$reason[m]<-"SYNTHETIC_PHYSICAL_ABSENCE"
v$source_state[71]<-"synthetic-exception";v$state[71]<-"UNRESOLVED_SOURCE_STATE";v$reason[71]<-"SYNTHETIC_APPROVED_EXCEPTION"
a<-v;con<-setNames(rep(list(rep(paste(rep("a",64),collapse=""),2)),3),c("source","ledger","state_inventory"))
r<-fi22_build(i,v,a);q<-qc_general_fi22(r,i,a,con)
stopifnot(all(q$status$pass),identical(r$participants$n_available[1:4],c(18L,17L,0L,21L)),is.na(r$participants$score[2]),is.na(r$participants$score[3]))
perm<-rev(seq_len(nrow(v)));r2<-fi22_build(i,v[perm,],a)
stopifnot(identical(r$participants,r2$participants))
invisible(qc_general_fi22(r2,i,a,con))
x<-v;x$assessment_ref[1]<-"future";bad(fi22_build(i,x,a))
x<-v;x$information_date[1]<-as.Date("2020-01-02");bad(fi22_build(i,x,x))
x<-v;x$item[1]<-"RAW-037";bad(fi22_build(i,x,x))
bad(fi22_build(i,v[-1,],a));bad(fi22_build(i,rbind(v,v[1,]),a))
x<-v;x$state[1]<-"OTHER_EXECUTION_CRITICAL";bad(fi22_build(i,x,x))
x<-r;x$participants$score[1]<-.999;bad(qc_general_fi22(x,i,a,con))
x<-r;x$items$denominator_contribution[1]<-1L;bad(qc_general_fi22(x,i,a,con))
x<-r;x$items$deficit_score[100]<-.123;bad(qc_general_fi22(x,i,a,con))
x<-con;x$source[2]<-paste(rep("b",64),collapse="");bad(qc_general_fi22(r,i,a,x))
for(st in list(q$status[FALSE,],q$status[-1,],rbind(q$status,q$status[1,]))) bad(fi22_gate(st))
st<-q$status;st$pass[1]<-NA;bad(fi22_gate(st));st<-q$status;st$assertion[1]<-"unknown";bad(fi22_gate(st))
cat("GENERAL_FI_22 synthetic mapping, 479 identity, coverage, leakage and K18 negative tests PASS\n")

# End-to-end protected runner using only synthetic temporary files.
tmp<-tempfile("fi22_synthetic_");dir.create(tmp,mode="0700")
src<-file.path(tmp,"source.rds");led<-file.path(tmp,"ledger.rds");inv<-file.path(tmp,"states.rds")
saveRDS(list(synthetic=TRUE),src)
fm<-data.frame(item=c(setdiff(FI22_IDS,FI22_BALANCE),"RAW-037","RAW-038"),source_field=paste0("synthetic_field_",1:23))
ld<-i;ld$synthetic_age<-80
for(id in setdiff(FI22_IDS,FI22_BALANCE)) ld[[fm$source_field[match(id,fm$item)]]]<-a$source_state[a$item==id]
bal<-a$source_state[a$item==FI22_BALANCE];bal[is.na(bal)]<-"E1"
ld[[fm$source_field[22]]]<-bal;ld[[fm$source_field[23]]]<-bal
saveRDS(ld,led)
stopifnot(fi22_bind_ledger(ld,i,a,fm,"index_date","synthetic_age"))
x<-ld;x[[fm$source_field[1]]][1]<-"1";bad(fi22_bind_ledger(x,i,a,fm,"index_date","synthetic_age"))
x<-fm;x$source_field[1]<-x$source_field[2];bad(fi22_bind_ledger(ld,i,a,x,"index_date","synthetic_age"))
sha<-function(p) strsplit(system2("sha256sum",shQuote(p),stdout=TRUE)," ")[[1]][1]
saveRDS(list(index=i,cells=a,source_sha256=sha(src),ledger_sha256=sha(led),study_role_approval="GENERAL_FI_22_SEVEN_POINT_USER_APPROVAL_2026-09-10",composition=FI22_IDS,field_map=fm,index_date_field="index_date",index_age_field="synthetic_age"),inv)
Sys.setenv(DATA_ROOT=tmp,FI22_AUTH_SOURCE=src,FI22_LEDGER=led,FI22_APPROVED_STATE_INVENTORY=inv,
 FI22_SOURCE_SHA256=sha(src),FI22_LEDGER_SHA256=sha(led),FI22_STATE_INVENTORY_SHA256=sha(inv),FI22_PROTECTED_RESULT=file.path(tmp,"result.rds"))
run<-function() suppressWarnings(system2(file.path(R.home("bin"),"Rscript"),c("--vanilla","scripts/run_general_fi22.R"),stdout=TRUE,stderr=TRUE))
res<-run();stopifnot(is.null(attr(res,"status")),any(grepl("PARTICIPANT_K18_PASS",res,fixed=TRUE)))
saved<-readRDS(file.path(tmp,"result.rds"));stopifnot(identical(saved$result$participants,r$participants))
# Existing output cannot be overwritten; mismatched source version fails closed.
res<-run();stopifnot(identical(attr(res,"status"),1L))
Sys.setenv(FI22_PROTECTED_RESULT=file.path(tmp,"other.rds"));saveRDS(list(changed=TRUE),src)
res<-run();stopifnot(identical(attr(res,"status"),1L),!file.exists(file.path(tmp,"other.rds")))
cat("GENERAL_FI_22 synthetic runner, file hash continuity, protected roundtrip, overwrite and changed-source gates PASS\n")

# Fractional P1 scores: verify the approved sum/count formula exactly.
# mean() may use a different rounding path, so it is not a bitwise oracle.
f<-a
f$source_state[f$item==FI22_BALANCE]<-rep(c("2","7"),length.out=sum(f$item==FI22_BALANCE))
f$source_state[f$item=="RAW-005" & f$state=="SCORED_VALID"]<-"3"
fr<-fi22_build(i,f,f); fq<-qc_general_fi22(fr,i,f,con)
stopifnot(all(fq$status$pass))
for(j in which(fr$participants$n_available>=18)) {
 z<-fr$items$deficit_score[fi22_key(fr$items)==fi22_key(fr$participants)[j] & fr$items$state=="SCORED_VALID"]
 stopifnot(identical(fr$participants$score[j],sum(z)/length(z)))
}
x<-fr;x$participants$score[1]<-x$participants$score[1]+1e-12
bad(qc_general_fi22(x,i,f,con))
cat("GENERAL_FI_22 fractional sum/count QC and perturbation rejection PASS\n")
