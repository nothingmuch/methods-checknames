#include "EXTERN.h"
#include "XSUB.h"
#include "perl.h"
#include "embed.h"

STATIC OP *(*mcn_orig_check)(pTHX_ OP *op) = NULL;

OP * mcn_ck_entersub(pTHX_ OP *o) {
	OP *ret = mcn_orig_check(aTHX_ o);

	OP *prev = ((cUNOPo->op_first->op_sibling) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first;
	OP *o2 = prev->op_sibling;
	OP *cvop;

	for (cvop = o2; cvop->op_sibling; cvop = cvop->op_sibling);


	if (cvop->op_type == OP_METHOD_NAMED && o2->op_type == OP_PADSV) {
		SV *method_name = ((SVOP *)cvop)->op_sv;
	    SV *lexname = *av_fetch(PL_comppad_name, o2->op_targ, TRUE);

	    if (SvPAD_TYPED(lexname)) {
			/* FIXME add a hook if SvSTASH has meta, to let roles, metaclasses
			 * etc verify themselves */
			HV *stash = SvSTASH(lexname);
			const char * const name = SvPV_nolen(method_name);
			GV *gv = gv_fetchmethod(stash, name);

			if (!gv)
				Perl_croak(aTHX_ "No such method \"%s\" " 
						"for variable %s of type %s", 
						name, SvPV_nolen(lexname), HvNAME_get(stash));
		}
	}

	return ret;
}

MODULE = Methods::CheckNames	PACKAGE = Methods::CheckNames

PROTOTYPES: ENABLE

BOOT:
	mcn_orig_check = PL_check[OP_ENTERSUB];
	PL_check[OP_ENTERSUB] = mcn_ck_entersub;

