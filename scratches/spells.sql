create table dnd5e.spells
(
    name                varchar not null
        constraint spells_pk
            primary key,
    source              varchar,
    type                varchar,
    school              varchar,
    level               integer,
    casting_time        varchar,
    range               varchar,
    comp_verbal         boolean,
    comp_somatic        boolean,
    comp_material       boolean,
    materials           text,
    duration            varchar,
    concentration       boolean,
    description         text,
    spell_lists         jsonb,
    costly_components   boolean,
    materials_breakdown jsonb,
    inserted_at         timestamp,
    updated_at          timestamp
);

alter table dnd5e.spells
    owner to postgres;

