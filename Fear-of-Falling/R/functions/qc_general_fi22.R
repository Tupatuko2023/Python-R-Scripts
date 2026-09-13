# Separate participant-score profile. Does not replace FOF or balance QC.
FI22_ASSERTIONS<-c("population","identity","membership","source_states","time_boundary",
 "state_partition","mapping","missing_unresolved","denominator","coverage",
 "formula","range","one_balance","continuity","output_schema")
fi22_gate<-function(status) {
 if(!is.data.frame(status)||!identical(names(status),c("assertion","pass"))||
 nrow(status)!=length(FI22_ASSERTIONS)||anyDuplicated(status$assertion)||
 !setequal(status$assertion,FI22_ASSERTIONS)||!is.logical(status$pass)||
 anyNA(status$pass)||!all(status$pass)) fi22_stop()
 TRUE
}
fi22_oracle<-function(id,x) {
 if(id=="RAW-015") return(unname(c("0"=0,"1"=.5,"2"=.5,"3"=1)[x]))
 if(id=="RAW-039") return(ifelse(x=="E",1,as.numeric(gsub(",",".",x,fixed=TRUE))>=12)*1)
 if(id=="RAW-012") { t<-as.numeric(x);return(ifelse(t<18.5|t>=30,1,ifelse(t>=25,.5,0))) }
 if(id==FI22_BALANCE) { t<-as.numeric(x);return(ifelse(t==0,1,ifelse(t<=5,.67,ifelse(t<=10,.33,0)))) }
 if(id=="RAW-041") return(pmin(1,(5-as.numeric(x))/4))
 if(id=="RAW-005") return(as.numeric(x)/4)
 if(id %in% sprintf("RAW-%03d",c(8,17,18,21,22,23,31))) return(as.numeric(x)/2)
 as.numeric(x)
}
qc_general_fi22<-function(result,index,authorized_states,continuity,expected_n=479L) {
 p<-result$participants;v<-result$items
 if(!is.data.frame(p)||!is.data.frame(v)||!all(c(names(authorized_states),"deficit_score","denominator_contribution") %in% names(v))) fi22_stop()
 ik<-fi22_key(index);pk<-fi22_key(p);vk<-fi22_key(v);ak<-fi22_key(authorized_states)
 vi<-paste(vk,v$item,sep="|");ai<-paste(ak,authorized_states$item,sep="|")
 j<-match(vi,ai);pi<-match(vk,pk)
 if(anyNA(j)||anyNA(pi)||anyDuplicated(vi)||anyDuplicated(ai)||!setequal(vi,ai)) fi22_stop()
 valid<-v$state=="SCORED_VALID"
 if(anyNA(valid)) fi22_stop()
 expected<-rep(NA_real_,nrow(v))
 for(id in FI22_IDS) { ix<-which(valid & v$item==id);if(length(ix)) expected[ix]<-fi22_oracle(id,v$source_state[ix]) }
 counts<-vapply(seq_len(nrow(p)),function(i) sum(valid[pi==i]),1L)
 means<-vapply(seq_len(nrow(p)),function(i) if(counts[i]>=18) sum(expected[pi==i & valid])/counts[i] else NA_real_,0.0)
 ci<-c("source","ledger","state_inventory")
 con<-is.list(continuity)&&all(ci %in% names(continuity))&&all(vapply(ci,function(n) {
  x<-continuity[[n]]; is.character(x)&&length(x)==2&&!anyNA(x)&&all(grepl("^[a-f0-9]{64}$",x))&&identical(x[[1]],x[[2]]) },TRUE))
 same<-function(x,y) identical(unname(x),unname(y))
 checks<-c(nrow(p)==expected_n && nrow(index)==expected_n,
 !anyDuplicated(pk)&&!anyDuplicated(p$person_ref)&&setequal(pk,ik),
 nrow(v)==expected_n*22L && setequal(v$item,FI22_IDS)&&all(tabulate(pi,nbins=nrow(p))==22),
 all(vapply(names(authorized_states),function(n) same(v[[n]],authorized_states[[n]][j]),TRUE)),
 inherits(v$information_date,"Date")&&!anyNA(v$information_date)&&all(v$information_date<=index$index_date[match(vk,ik)]),
 all(v$state %in% c("SCORED_VALID","SOURCE_DEFINED_MISSING","UNRESOLVED_SOURCE_STATE")),
 same(v$deficit_score,expected),
 all(is.na(v$deficit_score[!valid]))&&same(v$denominator_contribution,as.integer(valid)),
 same(p$n_available,counts)&&all(counts>=0&counts<=22),
 same(p$score_state,ifelse(counts>=18,"SCORE_CALCULABLE","INSUFFICIENT_COVERAGE")),
 same(p$score,means),
 all(is.finite(p$score[counts>=18]))&&all(p$score[counts>=18]>=0&p$score[counts>=18]<=1)&&all(is.na(p$score[counts<18])),
 sum(v$item==FI22_BALANCE)==expected_n&&!any(v$item %in% c("RAW-037","RAW-038","RAW-009","RAW-043","RAW-025","RAW-040")),
 con,identical(names(p),c("person_ref","assessment_ref","n_available","score_state","score"))&&
 identical(names(v),c(names(authorized_states),"deficit_score","denominator_contribution")))
 status<-data.frame(assertion=FI22_ASSERTIONS,pass=checks)
 fi22_gate(status)
 list(status=status,coverage=table(factor(p$n_available,levels=0:22)),
 score_states=table(p$score_state),item_states=table(v$item,v$state))
}
