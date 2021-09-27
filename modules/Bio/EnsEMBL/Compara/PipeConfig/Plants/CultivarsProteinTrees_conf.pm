=head1 LICENSE

See the NOTICE file distributed with this work for additional information
regarding copyright ownership.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 NAME

Bio::EnsEMBL::Compara::PipeConfig::Plants::CultivarsProteinTrees_conf

=head1 SYNOPSIS

    init_pipeline.pl Bio::EnsEMBL::Compara::PipeConfig::Plants::CultivarsProteinTrees_conf -host mysql-ens-compara-prod-X -port XXXX \
        -collection <strain_collection>

=head1 DESCRIPTION

The Plants Cultivars PipeConfig file for ProteinTrees pipeline that should automate most of the
pre-execution tasks.

=cut

package Bio::EnsEMBL::Compara::PipeConfig::Plants::CultivarsProteinTrees_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Compara::PipeConfig::Plants::ProteinTrees_conf');


sub default_options {
    my ($self) = @_;

    return {
        %{$self->SUPER::default_options},

        # Tree building parameters:
        'use_raxml'             => 1,
        'use_dna_for_phylogeny' => 1,

        # Mapping parameters:
        'do_stable_id_mapping'  => 0,
        'do_treefam_xref'       => 0,

        # Collection in master that will have overlapping data:
        'ref_collection' => 'default',

        # Extra analyses:
        # Gain/loss analysis?
        'do_cafe'    => 0,
        # Do we want the Gene QC part to run?
        'do_gene_qc' => 0,

        'multifurcation_deletes_all_subnodes' => undef,
    };
}


sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{$self->SUPER::pipeline_wide_parameters},

        'cdna'           => $self->o('use_dna_for_phylogeny'),
        'ref_collection' => $self->o('ref_collection'),
    }
}


sub core_pipeline_analyses {
    my ($self) = @_;
    return [
        @{$self->SUPER::core_pipeline_analyses},

        # Include strain-specific analyses
        {   -logic_name => 'check_strains_cluster_factory',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -parameters => {
                'inputquery' => 'SELECT root_id AS gene_tree_id FROM gene_tree_root WHERE tree_type = "tree" AND clusterset_id="default"',
            },
            -flow_into  => {
                '2->A' => [ 'cleanup_strains_clusters' ],
                'A->1' => [ 'hc_clusters' ],
            },
            -rc_name    => '1Gb_job',
        },

        {   -logic_name => 'cleanup_strains_clusters',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::RemoveOverlappingClusters',
        },

        {   -logic_name => 'remove_overlapping_homologies',
            -module     => 'Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::RemoveOverlappingHomologies',
        },
    ]
}


sub tweak_analyses {
    my $self = shift;
    my $analyses_by_name = shift;

    $analyses_by_name->{'make_treebest_species_tree'}->{'-parameters'}->{'allow_subtaxa'} = 1;  # We have sub-species
    $analyses_by_name->{'make_treebest_species_tree'}->{'-parameters'}->{'multifurcation_deletes_all_subnodes'} = $self->o('multifurcation_deletes_all_subnodes');
    $analyses_by_name->{'expand_clusters_with_projections'}->{'-rc_name'} = '500Mb_job';
    $analyses_by_name->{'split_genes'}->{'-hive_capacity'} = 300;

    # Wire up cultivar-specific analyses
    $analyses_by_name->{'remove_blacklisted_genes'}->{'-flow_into'} = ['check_strains_cluster_factory'];
    push @{$analyses_by_name->{'hc_global_tree_set'}->{'-flow_into'}}, 'remove_overlapping_homologies';
}


1;
