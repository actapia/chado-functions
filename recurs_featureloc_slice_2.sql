create or replace function public.recurs_featureloc_slice(varchar, bigint, bigint)
       returns setof featureloc
       language sql
as $function$with recursive rec_features as (
select fl.* from featureloc fl inner join feature f on fl.srcfeature_id = f.feature_id where f.name = $1 and fl.fmax >= least($2,$3) and fl.fmin <= greatest($2,$3)
union all
select fl2.featureloc_id as featureloc_id,
       fl2.feature_id as feature_id,       
       fl2.srcfeature_id as srcfeature_id,
       fl2.fmin+o.fmin as fmin,
       /* is_fmin_partial represents whether the true fmin is known or not.
       	  Here, is_fmin_partial will be set to TRUE if any ancestors have it set to true.
       	  Technically, we could know a feature's position relative to its src, but not relative to its src's src, but
	  that shouldn't be important for this application. */
       fl2.is_fmin_partial or o.is_fmin_partial as is_fmin_partial,
       fl2.fmax+o.fmin as fmax,
       fl2.is_fmax_partial or o.is_fmax_partial as is_fmax_partial,
       (case when o.strand = 0 then fl2.strand else fl2.strand * o.strand end) as strand,
       /* Not sure about phase... */
       (case when o.phase is NULL then fl2.phase else (fl2.phase+o.phase)%3 end) as phase,
       fl2.residue_info as residue_info,
       fl2.locgroup as locgroup,
       fl2.rank as rank
       from featureloc fl2 inner join rec_features o on o.feature_id = fl2.srcfeature_id and fl2.fmax >= least($2,$3)-o.fmin and fl2.fmin <= greatest($2,$3)-o.fmin
)
select * from rec_features$function$
