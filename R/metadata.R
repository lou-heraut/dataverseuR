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


replicate_typeName = function (metadata, typeName, n) {
    if (is.list(metadata)) {
        return (lapply(metadata, function(x) {

            if ("value" %in% names(x) && is.list(x$value)) {
                ok = FALSE
                if (typeName %in% names(x$value)) {
                    ok = TRUE
                    tmp_save = x$value
                } else if (length(x$value) > 0 &&
                           typeName %in% names(x$value[[1]])) {
                    ok = TRUE
                    tmp_save = x$value[[1]]
                }
                if (ok) {
                    tmp = tmp_save
                    tmp_all = list()
                    for (i in 1:n) {
                        for (tp in names(tmp_save)) {
                            tmp[[tp]]$typeName =
                                paste0(tmp_save[[tp]]$typeName, i)
                        }
                        tmp_all = append(tmp_all, list(tmp))
                    }
                    x$value = tmp_all
                }
                
            }
            x[] = replicate_typeName(x, typeName, n)
            return (x)
        }))
    }
    return (metadata)
}


add_typeName = function (metadata, typeName, value) {
    if (is.list(metadata)) {
        return (lapply(metadata, function(x) {

            if ("typeName" %in% names(x)) {
                if (x$typeName == typeName) {
                    if (x$multiple) {
                        x$value = list(value)
                    } else {
                        x$value = value
                    }
                    if (grepl("[[:digit:]]+$", x$typeName)) {
                        x$typeName = gsub("[[:digit:]]+$", "",
                                          x$typeName)
                    }
                }
            }
            x[] = add_typeName(x, typeName, value)
            return (x)
        }))
    }
    return (metadata)
}


clean_metadata_hide = function (metadata) {
    tmpAll = c("value", "fields")

    if (is.list(metadata)) {
        return (lapply(metadata, function(x) {

            for (name in names(x)) {
                if (is.list(x[[name]])) {
                    get_n = function (xx) {
                        ok = tmpAll %in% names(xx)
                        if (any(ok)) {
                            tmp = tmpAll[ok]
                            if (is.character(xx[[tmp]])) {
                                n = nchar(xx[[tmp]])
                            } else {
                                n = 888
                            }
                        } else {
                            n = 999
                        }
                        return (n)
                    }

                    ok = names(x[[name]]) %in% tmpAll
                    if (sum(ok) == 1) {
                        tmp = names(x[[name]])[ok]
                        if (!is.list(x[[name]][[tmp]])) {
                            if (nchar(x[[name]][[tmp]]) == 0) {
                                x = x[names(x) != name]
                            }
                        }
                        
                    } else {
                        n = sapply(x[[name]], get_n)
                        if (all(n == 0)) {
                            x[[name]] = ""
                        } else {
                            x[[name]] = x[[name]][n > 0]
                        }
                    }
                }
            }
            if (length(x) == 0) {
                x = c(value="")
            }
            x[] = clean_metadata_hide(x)
            return (x)
        }))
    }
    return (metadata)
}


clean_metadata = function (metadata) {
    get_condition = function (x) {
        if (is.list(x$fields)) {
            ok = any(nchar(unlist(x$fields)) == 0)
        } else {
            ok = x$fields == ""
        }
    }
    ok = any(sapply(metadata$datasetVersion$metadataBlocks,
                    get_condition))
    while (ok) {
        metadata = clean_metadata_hide(metadata)
        ok = any(sapply(metadata$datasetVersion$metadataBlocks,
                        get_condition))
    }
    return (metadata)
}


# generate_metadata_json_hide = function(metadata_yml,
#                                        res=list(group=c(),
#                                                 meta=dplyr::tibble())) {
#     if (is.list(metadata_yml)) {
#         for (i in 1:length(metadata_yml)) {
#             typeName = names(metadata_yml)[i]
#             value = metadata_yml[[i]]
#             if (is.character(value)) {
#                 line = dplyr::tibble(typeName=typeName,
#                                      value=value)
#                 res$meta = dplyr::bind_rows(res$meta,
#                                             line)
#             } else if (is.list(value)) {
#                 res$group = c(res$group, typeName)
#             }
#             res = generate_metadata_json_hide(value, res)
#         }
#     }
#     return (res)
# }


generate_metadata_json_hide = function(metadata_yml) {
    metadata_json = dplyr::tibble()
    for (i in 1:length(metadata_yml)) {

        field_value = metadata_yml[[i]]
        field_name = names(metadata_yml)[i]
        
        if (is.character(field_value)) {
            meta = dplyr::tibble(typeName=field_name,
                                 value=field_value,
                                 group=NA)
            metadata_json = dplyr::bind_rows(metadata_json,
                                            meta)
        
        } else if (is.list(field_value)) {
            for (element in field_value) {
                for (j in 1:length(element)) {
                    x_value = element[[j]]
                    x_name = names(element)[j]
                    meta =
                        dplyr::tibble(typeName=x_name,
                                      value=x_value,
                                      group=field_name)
                    
                    metadata_json =
                        dplyr::bind_rows(metadata_json,
                                         meta)
                }
            }
        }
    }
    return (metadata_json)
}


format_metadata_tbl = function (metadata_tbl) {
    metadata_tbl =
        dplyr::mutate(dplyr::group_by(metadata_tbl, typeName),
                      group_index=ifelse(
                          !is.na(typeName) &
                          dplyr::n() > 1,
                          dplyr::row_number(),
                          NA))
    metadata_tbl = dplyr::ungroup(metadata_tbl)
    return (metadata_tbl)
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
    
    metadata_json_path = c()
    for (mpath_yml in metadata_yml_path) {
        
        full_template_path =
            system.file("extdata",
                        "RDG_full_metadata_template.json",
                        package="dataverseuR")
        
        metadata_json = jsonlite::fromJSON(full_template_path,
                                           simplifyVector=FALSE,
                                           simplifyDataFrame=FALSE)

        mpath_json = gsub(".yml", ".json", mpath_yml)
        metadata_yml = yaml::read_yaml(mpath_yml)

        metadata_tbl = generate_metadata_json_hide(metadata_yml)
        metadata_tbl = format_metadata_tbl(metadata_tbl)

        Ok = !is.na(metadata_tbl$group_index)
        metadata_tbl$typeName[Ok] =
            paste0(metadata_tbl$typeName[Ok],
                   metadata_tbl$group_index[Ok])
        
        TypeNames = metadata_tbl$typeName
        TypeNames_Num = TypeNames[grepl("[[:digit:]]+$", TypeNames)]
        TypeNames_Num_noNum = unique(gsub("[[:digit:]]+$", "",
                                          TypeNames_Num))

        get_Num = function (x, All) {
            pattern = paste0("^", x, "[[:digit:]]+$")
            max(as.numeric(stringr::str_extract(All[grepl(pattern, All)],
                                                "[[:digit:]]+$")))
        }

        TypeNames_Num_noNum_n = sapply(TypeNames_Num_noNum,
                                       get_Num,
                                       All=TypeNames_Num)

        for (i in 1:length(TypeNames_Num_noNum_n)) {
            n = TypeNames_Num_noNum_n[i]
            typeName = names(TypeNames_Num_noNum_n)[i]
            if (!(paste0(typeName, n) %in% unlist(metadata_json))) {
                metadata_json = replicate_typeName(metadata_json, typeName, n)
            }
        }

        for (typeName in TypeNames) {
            value = metadata_tbl$value[metadata_tbl$typeName ==
                                       typeName]
            metadata_json = add_typeName(metadata_json, typeName, value)
        }
        metadata_json = clean_metadata(metadata_json)

        metadata_json = jsonlite::toJSON(metadata_json,
                                         pretty=TRUE,
                                         auto_unbox=TRUE)
        
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


# convert_metadata_to_yml_hide = function(metadata_yml,
#                                         res=list(group=c(),
#                                                  meta=dplyr::tibble()),
#                                         previous="",
#                                         multipleGroup=NA) {
#     if (is.list(metadata_yml)) {
#         for (x in metadata_yml) {

#             if ("typeName" %in% names(x) &
#                 "value" %in% names(x)) {
#                 if (is.character(x$value)) {
#                     print(x$typeName)
#                     following = gsub("[[:upper:]].*", "",
#                                      x$typeName)
#                     print(following)
#                     following = following[!is.na(following)]
#                     print("")
                    
#                     line = dplyr::tibble(typeName=x$typeName,
#                                          value=x$value,
#                                          group=multipleGroup)
#                     if (previous[1] != following[1]) {
#                         empty = dplyr::tibble(typeName="newline",
#                                               value="",
#                                               group=NA)
#                         res$meta =
#                             dplyr::bind_rows(res$meta,
#                                              empty)
#                         multipleGroup = NA
#                     }
#                     res$meta = dplyr::bind_rows(res$meta,
#                                                 line)
#                     previous = following
                    

#                 } else if (is.list(x$value)) {
#                     res$group = c(res$group, x$typeName)
#                     multipleGroup = x$typeName
#                 }
#             }
#             res = convert_metadata_to_yml_hide(x, res,
#                                                previous,
#                                                multipleGroup)
#         }
#     }
#     return (res)
# }


convert_metadata_to_yml_hide = function(metadata_json) {
    metadata_yml = dplyr::tibble()
    for (block in metadata_json$latestVersion$metadataBlocks) {
        for (field in block$fields) {
            if (is.character(field$value)) {
                meta = dplyr::tibble(typeName=field$typeName,
                                     value=field$value,
                                     group=NA)
                metadata_yml = dplyr::bind_rows(metadata_yml,
                                                meta)
                
            } else if (is.list(field$value)) {
                for (element in field$value) {
                    for (x in element) {
                        if ("typeName" %in% names(x) &
                            "value" %in% names(x)) {        
                            meta =
                                dplyr::tibble(typeName=x$typeName,
                                              value=x$value,
                                              group=field$typeName)
                            metadata_yml =
                                dplyr::bind_rows(metadata_yml,
                                                 meta)
                        }
                    }
                }
            }
            empty = dplyr::tibble(typeName="newline",
                                  value="",
                                  group=NA)
            metadata_yml = dplyr::bind_rows(metadata_yml, empty)
        }
    }
    return (metadata_yml)
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
    
    metadata_yml_path = c()
    for (mpath_json in metadata_json_path) {
        
        metadata_json = jsonlite::fromJSON(mpath_json,
                                           simplifyVector=FALSE,
                                           simplifyDataFrame=FALSE)
        
        metadata_tbl = convert_metadata_to_yml_hide(metadata_json)
        metadata_tbl = format_metadata_tbl(metadata_tbl)

        typeName = metadata_tbl$typeName
        Ok = typeName == "newline"
        metadata_tbl$typeName[Ok] =
            paste0(typeName[Ok],
                   metadata_tbl$group_index[Ok])
        
        group_order = metadata_tbl$group
        Ok = is.na(group_order)
        group_order[Ok] = metadata_tbl$typeName[Ok]
        group_order = unique(group_order)
        
        meta_list = as.list(dplyr::group_split(metadata_tbl,
                                               group))
        names(meta_list) = unique(unlist(sapply(meta_list,
                                                "[[", "group")))
        meta = list()
        nItem = length(meta_list)
        
        for (i in 1:nItem) {

            item = meta_list[[i]]
            name = names(meta_list)[i]
            
            if (is.na(name)) {
                item_list = as.list(tibble::deframe(dplyr::select(item,
                                                                  typeName,
                                                                  value)))
                meta = append(meta, item_list)
                
            } else {
                item_list = 
                    dplyr::summarise(dplyr::group_by(item,
                                                     group_index),
                                     value=list(tibble::deframe(dplyr::pick(typeName,
                                                                     value))),
                                     .groups="drop")
                item_list = lapply(item_list$value, as.list)
                meta = append(meta, list(item_list))
                names(meta)[length(meta)] = name
            }
        }

        meta = meta[group_order]
        yaml_text = yaml::as.yaml(meta)
        Lines = strsplit(yaml_text, "\n")[[1]]
        Ok = grepl("^newline[[:digit:]]+[:]", Lines)
        Lines[Ok] = ""
        Lines = Lines[c(TRUE, Lines[-1] !=
                              Lines[-length(Lines)])]    
        header_path = system.file(file.path("templates",
                                            "header.txt"),
                                  package="dataverseuR")
        header = readLines(header_path)
        Lines = c(header, Lines)
        mpath_yml = gsub(".json", ".yml", mpath_json)

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
