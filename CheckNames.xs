#include "EXTERN.h"
#include "XSUB.h"
#include "perl.h"
#include "embed.h"
#include "ppport.h"

#ifndef SvPAD_TYPED
#define SvPAD_TYPED(sv) \
	(SvFLAGS(sv) & SVpad_TYPED)
#endif

#if PERL_VERSION < 6
#ifdef PERL_OBJECT
#define PL_check this->check
#else
#define PL_check check
#endif
#endif

STATIC OP *(*mcn_orig_check)(pTHX_ OP *op) = NULL;

STATIC char *get_method_op_name(pTHX_ OP *cvop) {
#if PERL_VERSION >= 6
	if (cvop->op_type == OP_METHOD_NAMED) {
		SV *method_name = ((SVOP *)cvop)->op_sv;
		return SvPV_nolen(method_name);
	} else {
		return NULL;
	}
#else
	if ( cvop->op_type == OP_METHOD ) {
		OP *constop = ((UNOP*)cvop)->op_first;
		if ( constop->op_type == OP_CONST ) {
			SV *method_name = ((SVOP *)constop)->op_sv;
			if ( SvPOK(method_name) )
				return SvPV_nolen(method_name);
		}
	}
	return NULL;
#endif
}

STATIC SV *get_inv_sv(pTHX_ OP *o2) {
	if (o2->op_type == OP_PADSV) {
		SV **lexname = av_fetch(PL_comppad_name, o2->op_targ, TRUE);
		return lexname ? *lexname : NULL;
	}
}

STATIC HV *get_inv_stash(pTHX_ SV *lexname) {
#ifdef SVpad_TYPED
	if (SvPAD_TYPED(lexname))
#endif
		return SvSTASH(lexname);
	return NULL;
}

OP * mcn_ck_entersub(pTHX_ OP *o) {
	OP *ret = mcn_orig_check(aTHX_ o);

	OP *prev = ((cUNOPo->op_first->op_sibling) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first;
	OP *o2 = prev->op_sibling;
	OP *cvop;
	char *name;

	for (cvop = o2; cvop->op_sibling; cvop = cvop->op_sibling);

	if ( name = get_method_op_name(aTHX_ cvop) ) {
		SV *lexname = get_inv_sv(aTHX_ o2);

		if ( lexname ) {
			HV *stash = get_inv_stash(aTHX_ lexname);

			if ( stash ) {
				/* FIXME add a hook if SvSTASH has meta, to let roles, metaclasses
				 * etc verify themselves */
				GV *gv = gv_fetchmethod(stash, name);

				if (!gv)
					Perl_croak(aTHX_ "No such method \"%s\" " 
							"for variable %s of type %s", 
							name, SvPV_nolen(lexname), HvNAME(stash));
			}
		}
	}

	return ret;
}

MODULE = Methods::CheckNames	PACKAGE = Methods::CheckNames

PROTOTYPES: ENABLE

BOOT:
	mcn_orig_check = PL_check[OP_ENTERSUB];
	PL_check[OP_ENTERSUB] = mcn_ck_entersub;

