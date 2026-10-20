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


check_yml_format = function (path) {
    if (!grepl("\\.ya?ml$", path)) {
        stop(paste0(basename(path), " is not a YAML file."))
    }
}


check_json_format = function (path) {
    if (!grepl("\\.json$", path, ignore.case=TRUE)) {
        stop(paste0(basename(path), " is not a JSON file."))
    }
}


check_dir = function (path) {
    if (!dir.exists(dirname(path))) {
        dir.create(dirname(path), recursive=TRUE)
    }
}


# Column names used unquoted in dplyr and tidyr calls, declared here so that
# R CMD check does not take them for undefined global variables.
utils::globalVariables(c("categories", "dataFile", "description",
                         "global_id", "persistentId"))


# Fonction pour sanitizer les DOI en noms de dossiers
sanitize_doi = function(doi) {
    sanitized = gsub(":", "_", doi)
    sanitized = gsub("/", "_", sanitized)
    sanitized = gsub("\\.", "-", sanitized)
    return (sanitized)
}


# Reads a YAML file keeping every value as written: no guessing of numbers or
# booleans, so that "1.10" or "no" stay texts.
read_yml = function (path) {
    types = c("int", "int#oct", "int#hex", "int#base60",
              "float", "float#fix", "float#exp", "float#base60",
              "float#inf", "float#neginf", "float#nan",
              "bool#yes", "bool#no")
    handlers = rep(list(function (x) x), length(types))
    names(handlers) = types
    return (yaml::read_yaml(path, handlers=handlers))
}
