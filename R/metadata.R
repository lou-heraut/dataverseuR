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


format_full_metadata_hide = function(metadata) {
    if (is.list(metadata)) {
        return(lapply(metadata, function(x) {
            if ("multiple" %in% names(x) && x$multiple) {
                x$value = x$value[1]
                # x$multiple = FALSE
            }
            if ("value" %in% names(x) && is.character(x$value)) {
                if (x$multiple) {
                    x$value = list()
                } else {
                    x$value = ""
                }
            }
            x[] = format_full_metadata_hide(x)
            return(x)
        }))
    }
    return(metadata)
}


format_full_metadata = function (file="rechercheDataGouv-full-metadata.json",
                                 dev=FALSE) {

    if (dev) {
        path = file.path("inst", "extdata", file)
    } else {
        path = system.file("extdata", file, package="dataverseuR")
    }
    metadata = jsonlite::fromJSON(path,
                                  simplifyDataFrame=FALSE)
    
    metadata = format_full_metadata_hide(metadata)

    if (dev) {
        full_template_path = file.path("inst", "extdata",
                                       "RDG_full_metadata_template.json")
    } else {
        full_template_path = system.file("extdata",
                                         "RDG_full_metadata_template.json",
                                         package="dataverseuR")
    }
    write(jsonlite::toJSON(metadata,
                           pretty=TRUE,
                           auto_unbox=TRUE),
          full_template_path)
}


#' @title initialise_metadata
#' @description Create an empty example for a dataverse YAML metadata file.
#' @param metadata_yml_path A character string specifying the path to which the YAML metadata template should be written. By default, `"metadata.yml"` in the working directory.
#' @param overwrite A logical value indicating whether to overwrite an existing metadata template. Defaults to FALSE.
#' @return The function returns the path to the created .env file.
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @examples
#' \dontrun{
#' # Create the metadata template to the working directory
#' initialise_metadata()
#' # or create the metadata template in a remote location
#' initialise_metadata("path/to/metadata_project.yml")
#' }
#' @md
#' @export
initialise_metadata = function(metadata_yml_path="metadata.yml",
                               overwrite=FALSE) {
    check_yml_format(metadata_yml_path)
    check_dir(metadata_yml_path)    
    template_from_path = system.file("templates", "metadata_template.yml",
                                     package="dataverseuR")
    file.copy(template_from_path, metadata_yml_path, overwrite=overwrite)
}

# The full metadata template: every field of the Recherche Data Gouv blocks,
# empty, with the license and metadata language sent along with them.
read_metadata_template = function () {
    template_path = system.file("extdata", "RDG_full_metadata_template.json",
                                package="dataverseuR")
    return (jsonlite::fromJSON(template_path, simplifyVector=FALSE))
}


# The fields of the template by name, each with its block and, for a compound
# field, its sub-fields by name.
get_metadata_fields = function (template) {
    fields = list()
    for (block in names(template$datasetVersion$metadataBlocks)) {
        for (field in template$datasetVersion$metadataBlocks[[block]]$fields) {
            field$block = block
            if (field$typeClass == "compound") {
                subfields = if (field$multiple) field$value[[1]] else field$value
                names(subfields) = sapply(subfields, "[[", "typeName")
                field$subfields = subfields
            }
            fields[[field$typeName]] = field
        }
    }
    return (fields)
}


# Sub-fields written alone, like "country: France", make the single element of
# their compound field, as long as that field is not written as well.
group_subfields = function (metadata_yml, fields) {
    parents = c()
    for (field in fields) {
        parents[names(field$subfields)] = field$typeName
    }
    alone = intersect(names(metadata_yml), names(parents))
    for (parent in unique(parents[alone])) {
        names_alone = alone[parents[alone] == parent]
        if (parent %in% names(metadata_yml)) {
            stop(paste0(paste0(names_alone, collapse=", "),
                        " should be written inside ", parent, "."))
        }
        element = metadata_yml[names_alone]
        metadata_yml[[parent]] =
            if (fields[[parent]]$multiple) list(element) else element
    }
    return (metadata_yml[setdiff(names(metadata_yml), alone)])
}


# Removes empty values, then the elements and fields left empty.
drop_empty = function (x) {
    if (is.list(x)) {
        x = lapply(x, drop_empty)
        return (x[lengths(x) > 0])
    }
    return (x[!is.na(x) & nchar(x) > 0])
}


# A Dataverse field from its YAML value. A compound field holds one or several
# elements, each a set of sub-fields described by the template.
to_json_field = function (field, value) {
    if (field$typeClass == "compound") {
        subfields = field$subfields
        # A single element may be written without the dash of a list.
        if (!field$multiple || !is.null(names(value))) {
            value = list(value)
        }
        elements = lapply(value, function (element) {
            if (!is.list(element) || is.null(names(element))) {
                stop(paste0(field$typeName, " is made of sub-fields: ",
                            paste0(names(subfields), collapse=", "), "."))
            }
            unknown = setdiff(names(element), names(subfields))
            if (length(unknown) > 0) {
                stop(paste0("Unknown sub-field of ", field$typeName, ": ",
                            paste0(unknown, collapse=", ")))
            }
            mapply(to_json_field, subfields[names(element)], element,
                   SIMPLIFY=FALSE)
        })
        value = if (field$multiple) elements else elements[[1]]
    } else if (field$multiple) {
        value = as.list(value)
    } else if (length(value) > 1) {
        stop(paste0(field$typeName, " takes a single value."))
    }
    return (list(typeName=field$typeName, multiple=field$multiple,
                 typeClass=field$typeClass, value=value))
}


# The YAML value of a Dataverse field: a text for a single value, a list for
# several, one set of sub-fields per element for a compound field.
to_yml_value = function (field) {
    if (field$typeClass == "compound") {
        elements = if (field$multiple) field$value else list(field$value)
        elements = lapply(elements, function (element) {
            lapply(element, to_yml_value)
        })
        return (if (field$multiple) elements else elements[[1]])
    }
    return (unlist(field$value))
}


#' @title generate_metadata_json
#' @description Generate from a YAML metadata file a JSON metadata file used by dataverse to create or modify a dataset. See [initialise_metadata()] or [get_datasets_metadata()] and [convert_metadata_to_yml()] to get a metadata YAML file.
#' @param metadata_yml_path A character vector specifying the paths from which the YAML metadata should be read.
#' @param overwrite A logical value indicating whether to overwrite an existing metadata file. Defaults to FALSE.
#' @return A vector of character strings containing the JSON metadata paths.
#' @examples
#' \dontrun{
#' # First option 
#' # Get a YAML file from a template
#' initialise_metadata("metadata.yml")
#' # Customize the YAML file, then generate the JSON equivalent
#' metadata_json_path = generate_metadata_json("metadata.yml")
#'
#' # Second option
#' # Get a YAML file from a dataverse deposit
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' get_datasets_metadata(dataset_DOI, "metadata.json")
#' convert_metadata_to_yml("metadata.json")
#' # Customize the YAML file, then generate the JSON equivalent
#' metadata_json_path = generate_metadata_json("metadata.yml")
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @md
#' @export
generate_metadata_json = function (metadata_yml_path,
                                   overwrite=FALSE) {

    sapply(metadata_yml_path, check_yml_format)
    sapply(metadata_yml_path, check_dir)

    template = read_metadata_template()
    fields = get_metadata_fields(template)

    metadata_json_path = c()
    for (mpath_yml in metadata_yml_path) {

        metadata_yml = drop_empty(read_yml(mpath_yml))
        metadata_yml = group_subfields(metadata_yml, fields)
        unknown = setdiff(names(metadata_yml), names(fields))
        if (length(unknown) > 0) {
            stop(paste0("Unknown metadata field in ", basename(mpath_yml),
                        ": ", paste0(unknown, collapse=", ")))
        }

        blocks = list()
        for (name in names(metadata_yml)) {
            field = fields[[name]]
            blocks[[field$block]]$fields =
                append(blocks[[field$block]]$fields,
                       list(to_json_field(field, metadata_yml[[name]])))
        }
        metadata_json = template
        metadata_json$datasetVersion$metadataBlocks = blocks
        metadata_json = jsonlite::toJSON(metadata_json,
                                         pretty=TRUE,
                                         auto_unbox=TRUE)

        mpath_json = sub("\\.ya?ml$", ".json", mpath_yml)
        if (file.exists(mpath_json) & !overwrite) {
            message (paste0("Metadata file already exists in ",
                            mpath_json))
        } else {
            write(metadata_json, mpath_json)
        }
        metadata_json_path = c(metadata_json_path, mpath_json)
    }
    return (metadata_json_path)
}


#' @title convert_metadata_to_yml
#' @description Convert a metadata JSON file from the dataverse to a more user-friendly YAML metadata file. See [get_datasets_metadata()] to retrieve metadata JSON file from a dataverse deposit.
#' @param metadata_json_path A character vector specifying the paths from which the JSON metadata files should be converted.
#' @param overwrite A logical value indicating whether to overwrite an existing metadata file. Defaults to FALSE.
#' @return A vector of character strings containing the YAML metadata paths.
#' @examples
#' \dontrun{
#' metadata_yml_path = convert_metadata_to_yml("metadata.json")
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @md
#' @export
convert_metadata_to_yml = function (metadata_json_path,
                                    overwrite=FALSE) {

    sapply(metadata_json_path, check_json_format)
    sapply(metadata_json_path, check_dir)

    header_path = system.file("templates", "header.txt",
                              package="dataverseuR")
    header = readLines(header_path)

    metadata_yml_path = c()
    for (mpath_json in metadata_json_path) {

        metadata_json = jsonlite::fromJSON(mpath_json,
                                           simplifyVector=FALSE)
        # A dataset as downloaded, or as written by generate_metadata_json().
        version = metadata_json$latestVersion
        if (is.null(version)) {
            version = metadata_json$datasetVersion
        }
        if (is.null(version)) {
            stop(paste0(basename(mpath_json), " holds no dataset metadata."))
        }
        metadata_yml = list()
        for (block in version$metadataBlocks) {
            for (field in block$fields) {
                metadata_yml[[field$typeName]] = to_yml_value(field)
            }
        }
        metadata_yml = drop_empty(metadata_yml)

        body = sapply(names(metadata_yml), function (name) {
            yaml::as.yaml(metadata_yml[name])
        })
        # One blank line between fields.
        body = paste0(sub("\n$", "", body), collapse="\n\n")
        Lines = c(header, body)

        mpath_yml = sub("\\.json$", ".yml", mpath_json, ignore.case=TRUE)
        if (file.exists(mpath_yml) & !overwrite) {
            message (paste0("Metadata file already exists in ",
                            mpath_yml))
        } else {
            writeLines(Lines, mpath_yml)
        }
        metadata_yml_path = c(metadata_yml_path, mpath_yml)
    }
    return (metadata_yml_path)
}
