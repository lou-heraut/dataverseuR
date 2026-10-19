# Copyright 2025 Louis Héraut (louis.heraut@inrae.fr)*1
#
# *1   INRAE, France
#
# This file is part of dataverseuR R package.
#
# dataverseuR R package is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# dataverseuR R package is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with dataverseuR R package.
# If not, see <https://www.gnu.org/licenses/>.


#' @name dataverseuR
#' @title dataverseuR
#' @description A dataverse API wraper to enhance deposit procedure with user-friendly YAML parameterization files.
#' 
#' @details See [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR> for an easier approach.
#'
#' @author
#' Main Developer and Maintainer
#' - Louis Héraut <louis.heraut@inrae.fr> INRAE, UR RiverLy, Villeurbanne, France
#'   ORCID : 0009-0006-4372-0923
#' 
#' @seealso
#' To start :
#' - [create_dotenv()] for creating the environment file for credential
#'
#' For metadata generation :
#' - [initialise_metadata()] to get a simple YAML metadata template file
#' - [convert_metadata_to_yml()] to convert a JSON metadata file from the dataverse to a simplier YAML metadata file
#' - [generate_metadata_json()] to generate a JSON metadata file for the dataverse from a simplier YAML metadata file
#' 
#' For general API actions :
#' - [search_datasets()] to perform a search on dataverse
#' - [create_datasets()] to create datasets with a metadata JSON file
#' - [modify_datasets()] to modify datasets metadata with a metadata JSON file
#' - [add_datasets_files()] to add files to datasets 
#' - [delete_datasets_files()] to delete files from datasets
#' - [delete_all_datasets_files()] to delete all files from datasets
#' - [publish_datasets()] to publish datasets
#' - [delete_datasets()] to delete datasets
#'
#' For information about datasets :
#' - [get_datasets_metadata()] to get the metadata list of datasets
#' - [list_datasets_files()] to list files of datasets
#' - [download_datasets_files()] to download files of datasets
#' - [get_datasets_size()] to get the size of datasets
#' - [get_datasets_metrics()] to get the metrics about datasets
#'
#' Others :
#' - [convert_DOI_to_URL()] to convert a DOI to an URL
#' @md
NULL
