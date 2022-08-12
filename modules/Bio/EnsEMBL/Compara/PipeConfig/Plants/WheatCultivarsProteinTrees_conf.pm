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

Bio::EnsEMBL::Compara::PipeConfig::Plants::WheatCultivarsProteinTrees_conf

=head1 SYNOPSIS

    init_pipeline.pl Bio::EnsEMBL::Compara::PipeConfig::Plants::WheatCultivarsProteinTrees_conf -host mysql-ens-compara-prod-X -port XXXX

=head1 DESCRIPTION

The Wheat cultivars PipeConfig file for CultivarsProteinTrees pipeline that should automate most of the pre-execution tasks.

=cut

package Bio::EnsEMBL::Compara::PipeConfig::Plants::WheatCultivarsProteinTrees_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Compara::PipeConfig::Plants::CultivarsProteinTrees_conf');


sub default_options {
    my ($self) = @_;

    return {
        %{$self->SUPER::default_options},

        # Parameters to allow merging different runs of the pipeline
        'collection'       => 'wheat_cultivars',  # The name of the species-set within that division
        'dbID_range_index' => 20,
        'label_prefix'     => 'wheat_cultivars_',

        # Flatten all the species under the "Triticum" genus
        'multifurcation_deletes_all_subnodes' => [ 4564 ],

        # Clustering parameters:
        # List of species some genes have been projected from
        'projection_source_species_names' => ['triticum_aestivum'],

        # Parameters used by 'homology_dnds':
        'taxlevels' => ['Triticum'],

        # Threshold used by per_genome_qc in order to check if the amount of orphan genes are acceptable
        # values are lower than in the Plants config file because the clustering method is less comprehensive
        'mapped_gene_ratio_per_taxon' => {
            '1648030' => 0.75,
        },

        # GOC parameters
        'goc_taxlevels' => ['Triticum'],
    };
}


sub tweak_analyses {
    my $self = shift;
    my $analyses_by_name = shift;

    $analyses_by_name->{'fasttree'}->{'-parameters'}->{'cmd'} = '#fasttree_exe# -nosupport -pseudo -quiet -nopr -wag #alignment_file# > #output_file#';

    # Flow "examl_32_cores" #-2 to "fasttree"
    $analyses_by_name->{'examl_32_cores'}->{'-flow_into'}->{-2} = [ 'fasttree' ];
}


1;
