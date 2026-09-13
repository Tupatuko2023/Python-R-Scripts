# C22 only. Pure functions; caller owns protected input/output boundaries.
FI22_BALANCE <- "canonical single-leg-standing balance [named object; no candidate ID]"
FI22_IDS <- c(sprintf("RAW-%03d",c(1:5,8,12,17,18,21:24,26:29,31,41,15,39)), FI22_BALANCE)
fi22_stop <- function() stop("GENERAL_FI_22 contract violation",call.=FALSE)
fi22_key <- function(x) {
 if(!all(c("person_ref","assessment_ref") %in% names(x))) fi22_stop()
 if(anyNA(x$person_ref)||anyNA(x$assessment_ref)||any(!nzchar(x$person_ref))||any(!nzchar(x$assessment_ref))) fi22_stop()
 paste0(nchar(x$person_ref),":",x$person_ref,nchar(x$assessment_ref),":",x$assessment_ref)
}
fi22_maps <- function() {
 z<-list()
 for(id in sprintf("RAW-%03d",1:4)) z[[id]]<-c("0"=0,"1"=1)
 z[["RAW-005"]]<-c("0"=0,"1"=.25,"2"=.5,"3"=.75,"4"=1,"5"=NA_real_)
 for(id in sprintf("RAW-%03d",c(8,17,18,21,22,23,31))) z[[id]]<-c("0"=0,"1"=.5,"2"=1,"3"=NA_real_)
 for(id in sprintf("RAW-%03d",c(24,26,27,28,29))) z[[id]]<-c("0"=0,"1"=1,"2"=NA_real_)
 z[["RAW-041"]]<-c("0"=1,"1"=1,"2"=.75,"3"=.5,"4"=.25,"5"=0,"E1"=NA_real_)
 z
}
fi22_map <- function(id, raw) {
 if(length(id)!=1 || !id %in% FI22_IDS || !is.character(raw) || anyNA(raw)) fi22_stop()
 if(id=="RAW-015") return(derive_general_fi_raw015(raw)$raw015_deficit)
 if(id=="RAW-039") return(derive_general_fi_raw039(raw)$raw039_deficit)
 if(id=="RAW-012") {
  missing<-raw=="E1"; num<-suppressWarnings(as.numeric(raw))
  if(any(!missing & (!is.finite(num)|!grepl("^[0-9]+([.][0-9]+)?$",raw)))) fi22_stop()
  return(ifelse(missing,NA_real_,ifelse(num<18.5,1,ifelse(num<25,0,ifelse(num<30,.5,1)))))
 }
 if(id==FI22_BALANCE) {
  num<-suppressWarnings(as.numeric(raw))
  if(any(!grepl("^[0-9]+([.][0-9]+)?$",raw))) fi22_stop()
  return(score_general_fi_balance_p1(num,rep("CANONICAL_NUMERIC",length(raw)))$balance_deficit)
 }
 map<-fi22_maps()[[id]]
 if(any(!raw %in% names(map))) fi22_stop()
 unname(map[raw])
}
# cells and authorized_states must originate from independently verified,
# version-bound protected adapters. An arbitrary caller flag is not evidence.
fi22_build <- function(index, cells, authorized_states, expected_n=479L) {
 ik<-fi22_key(index)
 if(nrow(index)!=expected_n || anyDuplicated(ik)||anyDuplicated(index$person_ref) ||
    !all(c("index_date","primary_fi_index") %in% names(index)) ||
    !inherits(index$index_date,"Date") || anyNA(index$index_date) ||
    !is.logical(index$primary_fi_index)||anyNA(index$primary_fi_index)||!all(index$primary_fi_index)) fi22_stop()
 req<-c("person_ref","assessment_ref","item","source_state","state","reason","information_date")
 if(!setequal(names(cells),req)||!setequal(names(authorized_states),req)) fi22_stop()
 ck<-fi22_key(cells);ak<-fi22_key(authorized_states)
 full<-paste(ck,cells$item,sep="|"); approved<-paste(ak,authorized_states$item,sep="|")
 if(anyDuplicated(full)||anyDuplicated(approved)||!setequal(full,approved)||
    any(!cells$item %in% FI22_IDS)||nrow(cells)!=expected_n*22L||
    !all(ck %in% ik)) fi22_stop()
 j<-match(full,approved)
 for(n in req) if(!identical(cells[[n]],authorized_states[[n]][j])) fi22_stop()
 pi<-match(ck,ik)
 if(!inherits(cells$information_date,"Date")||anyNA(cells$information_date)||
    any(cells$information_date>index$index_date[pi])) fi22_stop()
 if(anyNA(cells$state)||anyNA(cells$reason)||any(!nzchar(cells$reason))||
    any(!cells$state %in% c("SCORED_VALID","SOURCE_DEFINED_MISSING","UNRESOLVED_SOURCE_STATE"))) fi22_stop()
 # All 22 unique slots required for every index, including unavailable items.
 if(any(tabulate(pi,nbins=expected_n)!=22L)) fi22_stop()
 score<-rep(NA_real_,nrow(cells))
 for(id in FI22_IDS) {
  ix<-which(cells$item==id & cells$state=="SCORED_VALID")
  if(length(ix)) score[ix]<-fi22_map(id,cells$source_state[ix])
 }
 valid<-cells$state=="SCORED_VALID"
 if(any(!is.finite(score[valid]))||any(score[valid]<0|score[valid]>1)||any(!is.na(score[!valid]))) fi22_stop()
 # Missing and unresolved classification is accepted only from the verified
 # upstream state inventory, never inferred from an unrecognized token.
 result<-index[c("person_ref","assessment_ref")]
 result$n_available<-as.integer(tabulate(pi[valid],nbins=expected_n))
 result$score_state<-ifelse(result$n_available>=18L,"SCORE_CALCULABLE","INSUFFICIENT_COVERAGE")
 result$score<-NA_real_
 for(i in which(result$n_available>=18L)) result$score[i]<-sum(score[pi==i & valid])/result$n_available[i]
 items<-cells;items$deficit_score<-score;items$denominator_contribution<-as.integer(valid)
 list(participants=result,items=items,composition=FI22_IDS,
      name="KAAOS multidomain deficit-accumulation score (22-item)")
}

# Lossless binding to the actual approved ledger, not merely to copied flags.
# field_map is part of the separately hash-bound source-state inventory.
fi22_bind_ledger<-function(ledger,index,cells,field_map,index_date_field,index_age_field) {
 required<-c(setdiff(FI22_IDS,FI22_BALANCE),"RAW-037","RAW-038")
 if(!identical(names(field_map),c("item","source_field"))||anyDuplicated(field_map$item)||
 anyDuplicated(field_map$source_field)||!setequal(field_map$item,required)||
 anyNA(field_map$source_field)||!all(field_map$source_field %in% names(ledger))||
 length(index_date_field)!=1||!index_date_field %in% names(ledger)||
 length(index_age_field)!=1||!index_age_field %in% names(ledger)||
 !"primary_fi_index" %in% names(ledger)||!is.logical(ledger$primary_fi_index)||anyNA(ledger$primary_fi_index)) fi22_stop()
 lk<-fi22_key(ledger);ik<-fi22_key(index);ck<-fi22_key(cells)
 if(anyDuplicated(lk)||!all(ik %in% lk)||!all(ck %in% ik)) fi22_stop()
 age<-suppressWarnings(as.numeric(ledger[[index_age_field]]))
 eligible<-ledger$primary_fi_index & !is.na(age) & is.finite(age) & age>=65
 if(sum(eligible)!=479L||!setequal(lk[eligible],ik)) fi22_stop()
 j<-match(ik,lk);ci<-match(ck,lk)
 if(!all(ledger$primary_fi_index[j] %in% TRUE)||
 !identical(as.Date(ledger[[index_date_field]][j]),index$index_date)) fi22_stop()
 for(id in setdiff(FI22_IDS,FI22_BALANCE)) {
  ix<-which(cells$item==id);field<-field_map$source_field[match(id,field_map$item)]
  if(!identical(as.character(ledger[[field]][ci[ix]]),cells$source_state[ix])) fi22_stop()
 }
 ix<-which(cells$item==FI22_BALANCE)
 r<-field_map$source_field[match("RAW-037",field_map$item)]
 l<-field_map$source_field[match("RAW-038",field_map$item)]
 # Both values are columns of one uniquely keyed ledger assessment.
 bound<-ledger[ci[ix],c("person_ref","assessment_ref",r,l),drop=FALSE]
 if(!identical(fi22_key(bound),ck[ix]) ||
    !identical(as.character(bound$assessment_ref),as.character(cells$assessment_ref[ix]))) fi22_stop()
 b<-derive_general_fi_canonical_balance(bound[[r]],bound[[l]],
   bound$assessment_ref,cells$assessment_ref[ix])
 expected<-ifelse(b$canonical_state=="CANONICAL_NUMERIC","SCORED_VALID",b$canonical_state)
 if(any(expected=="OTHER_EXECUTION_CRITICAL")||!identical(cells$state[ix],expected)||
 !identical(cells$source_state[ix],as.character(b$canonical_seconds))) fi22_stop()
 TRUE
}
