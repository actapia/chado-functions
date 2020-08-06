create or replace function public.feat_remapping(int)
       returns setof featureloc
       language sql
as $function$with recursive rec_featureloc as (
select fl.* from featureloc fl where fl.feature_id = $1
union all
select fl2.featureloc_id as featureloc_id,
       o.feature_id as feature_id,
       fl2.srcfeature_id as srcfeature_id,
       fl2.fmin+o.fmin as fmin,
       fl2.is_fmin_partial or o.is_fmin_partial as is_fmin_partial,
       fl2.fmin+o.fmax as fmax,
       fl2.is_fmax_partial or o.is_fmax_partial as is_fmax_partial,
       (case when fl2.strand = 0 then o.strand else fl2.strand * o.strand end) as strand,
       (case when fl2.phase is NULL then o.phase else (fl2.phase+o.phase)%3 end) as phase,
       o.residue_info as residue_info,
       o.locgroup as locgroup,
       o.rank as rank
       from featureloc fl2 inner join rec_featureloc o on fl2.feature_id = o.srcfeature_id
)
select rfl.* from rec_featureloc rfl full outer join featureloc fl3 on rfl.srcfeature_id = fl3.feature_id where fl3.feature_id is null and rfl.rank = 0$function$
