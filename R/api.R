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


#' @title create_dotenv
#' @description Create a default .env file necessary to fill in environment variables required for dataverse authentication.
#' @param dotenv_path A character string for the path of the .env file that will be created. By default, it create a file named `dist.env` in the working directory. This file should be rename `.env`.
#' @param overwrite A logical value indicating whether to overwrite an existing .env file. Defaults to FALSE.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return The function returns the path to the created .env file.
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @examples
#' \dontrun{
#' # Create the .env file to the working directory
#' create_dotenv()
#' # or create the .env file in a remote location with no informations displayed
#' create_dotenv("path/to/dir/.env-demo", verbose=FALSE)
#'
#' # Then load the environment variables with
#' dotenv::load_dot_env()
#' # or
#' dotenv::load_dot_env("path/to/dir/.env-demo")
#' }
#' @md
#' @export
create_dotenv = function(dotenv_path=file.path(getwd(), "dist.env"),
                         overwrite=FALSE,
                         verbose=TRUE) {
    
    dotenv_from_path = system.file("templates", "dist.env",
                                   package="dataverseuR")
    file.copy(dotenv_from_path, dotenv_path, overwrite=overwrite)

    if (verbose) {
        message(paste0("The '", basename(dotenv_path),
                       "' file has been copied to : '",
                       dotenv_path,
                       "'\n\nPLease fill in your credential and rename that file '.env'.\n/!\\ NEVER give your personnal credential through a GIT repo."))
    }
    return (dotenv_path)
}


search_metadata_blocks = function() {
    search_url = "https://entrepot.recherche.data.gouv.fr/api/metadatablocks/citation"
    # search_url = modify_url(base_url, query=query_params)
    response = httr::GET(search_url)
    
    if (httr::status_code(response) == 200) {
        metadata_blocks = httr::content(response, "parsed")
        return (metadata_blocks)
    } else {
        stop(paste0(httr::status_code(response), " ",
                    httr::content(response, "text")))
    }
}


convert_datasets_to_tibble_hide = function(dataset) {
    dataset_flat = purrr::map(dataset, function(x) {
        if (is.atomic(x)) {
            x
        } else {
            list(x)
        }
    })
    dplyr::as_tibble(dataset_flat) 
}

convert_datasets_search_to_tibble = function (datasets_search) {
    results = dplyr::tibble()
    for (dataset in datasets_search$items) {
        results_tmp = convert_datasets_to_tibble_hide(dataset)
        results = dplyr::bind_rows(results, results_tmp)
    }
    if (nrow(results) > 0) {
        results = dplyr::rename(results, dataset_DOI=global_id)
    }
    return (results)
}


#' @title convert_DOI_to_URL
#' @description Convert a DOI to a functional URL.
#' @param DOI A character string specifying the DOI to convert.
#' @return A character string for the associated URL.
#' @examples
#' convert_DOI_to_URL("doi:10.57745/LNBEGZ")
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @md
#' @export
convert_DOI_to_URL = function (DOI) {
    URL = gsub("doi[:]",
               "https://doi.org/",
               DOI)
    return (URL)
}


#' @title search_datasets
#' @description Performs a search query on the Dataverse API.
#' @param query A character string specifying the search query. The default value is `"*"` which means a search for all datasets.
#' 
#' More information on search formatting through an example:
#'
#' QUERY TYPE	     SYNTAX EXAMPLE                      DESCRIPTION
#' Basic Search	     query="climate"	                 Finds "climate" anywhere
#' Exact Phrase	     query='"climate change"'	         Finds the exact phrase
#' Wildcard (* & ?)  query="climat*" or query="cl?mate"	 Matches variations
#' Boolean Search    query="climate AND temperature"	 Combines terms
#' Field Search	     query="title:climate"	         Searches specific fields
#' Fuzzy Search	     query="climate~"	                 Finds similar words
#' Proximity Search  query='"climate temperature"~5'	 Finds nearby words
#' Regex (Limited)   query="climate*"                    Limited pattern matching
#' 
#' @param publication_status A character string specifying the publication status of the datasets. Valid options are "DRAFT", "RELEASED". The default is `"*"`, meaning all statuses.
#' @param type A character string specifying the type of object to search between `"dataverse"`, `"dataset"`, or `"file"`. The default is `"dataset"` for searching only dataset.
#' @param dataverse A character string specifying the dataverse to search within. If left empty, the search will query all available dataverses in the `BASE_URL`.
#' @param n_search An integer indicating the maximum number of results to return. Default is 10.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @return A tibble of the restult of the search.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' # A simple example to search all datasets from a dataverse
#' datasets = search_datasets(query="*",
#'                            publication_status="RELEASED",
#'                            type="dataset",
#'                            dataverse="riverly",
#'                            n_search=1000)
#'
#' # A more difficult one with a complexe query 
#' query = '(title:"résultats*" OR title:"incertitudes*") NOT kindOfDataOther:"notice"'
#' datasets = search_datasets(query=query,
#'                            publication_status="RELEASED",
#'                            type="dataset",
#'                            dataverse="explore2",
#'                            n_search=1000)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Search API documentation](https://guides.dataverse.org/en/5.3/api/search.html) <https://guides.dataverse.org/en/5.3/api/search.html>
#' @md
#' @export
search_datasets = function(query="*", publication_status="*",
                           type="dataset", dataverse="",
                           n_search=10,
                           BASE_URL=Sys.getenv("BASE_URL"),
                           API_TOKEN=Sys.getenv("API_TOKEN")) {

    query = gsub("[ ]", "+", query)
    q = paste0(paste0("q=", query), collapse="&")
    if (publication_status == "DRAFT") {
        fq = "fq=publicationStatus:Draft"
    } else if (publication_status == "RELEASED") {
        fq = "fq=publicationStatus:Published"
    } else {
        fq = paste0("fq=", publication_status) 
    }
    
    type = paste0(paste0("type=", type), collapse="&")
    subtree = paste0(paste0("subtree=", dataverse), collapse="&")
    # &metadata_fields=citation:author
    
    search_url = paste0(BASE_URL, "/api/search?",
                        q, "&",
                        fq, "&",
                        type, "&",
                        subtree, "&",
                        "per_page=", n_search)

    response = httr::GET(search_url,
                         httr::add_headers("X-Dataverse-key" = API_TOKEN))
    
    if (httr::status_code(response) != 200) {
        stop(paste0(httr::status_code(response), " ",
                    httr::content(response, "text")))
    }
    datasets = httr::content(response, "parsed")$data
    datasets = convert_datasets_search_to_tibble(datasets)
    return (datasets)
}


#' @title get_datasets_size
#' @description Retrieves the total storage size (in bytes) of a selection of datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A tibble containing datasets DOI and their corresponding total storage sizes in bytes.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' get_datasets_size(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/RiverLy_HCERES_2025/script.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/RiverLy_HCERES_2025/script.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#report-the-data-file-size-of-a-dataverse) <https://guides.dataverse.org/en/5.3/api/native-api.html#report-the-data-file-size-of-a-dataverse>
#' @md
#' @export
get_datasets_size = function(dataset_DOI,
                             BASE_URL=Sys.getenv("BASE_URL"),
                             API_TOKEN=Sys.getenv("API_TOKEN"),
                             verbose=TRUE) {

    results = dplyr::tibble()
    
    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        
        query_url = paste0(BASE_URL, "/api/datasets/:persistentId/storagesize/?persistentId=", dDOI)
        response = httr::GET(query_url, 
                             httr::add_headers("X-Dataverse-key"=API_TOKEN))
        
        if (httr::status_code(response) == 200) {
            size_value = httr::content(response,
                                       "parsed")$data$message
            size_value = gsub("(.*[:] )|( bytes)|(,)", "",
                              size_value)
            size_value = as.numeric(size_value)
        } else {
            warning(paste0(dDOI, " : ",
                           httr::status_code(response), " ",
                           httr::content(response, "text")))
            size_value = NA
        }
        
        results_tmp = dplyr::tibble(dataset_DOI=dDOI,
                                    storage_size_bytes=size_value)
        results = dplyr::bind_rows(results, results_tmp)

        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : size of dataset ", convert_DOI_to_URL(dDOI), " retrieved"))
    }
    
    results$storage_size_GB = round(results$storage_size_bytes/1024**3, 3)
    return(results)
}



#' @title get_datasets_metrics
#' @description Retrieves dataset metrics of views and downloads from a selection of datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A named list containing total views, unique views, total downloads, unique downloads, and citations.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' get_datasets_metrics(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/RiverLy_HCERES_2025/script.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/RiverLy_HCERES_2025/script.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#dataset-metrics) <https://guides.dataverse.org/en/5.3/api/native-api.html#dataset-metrics>
#' @md
#' @export
get_datasets_metrics = function(dataset_DOI,
                                BASE_URL=Sys.getenv("BASE_URL"),
                                API_TOKEN=Sys.getenv("API_TOKEN"),
                                verbose=TRUE) {

    results = dplyr::tibble()
    metrics = c("viewsTotal", "viewsUnique",
                "downloadsTotal", "downloadsUnique") #"citations"

    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        
        results_tmp = c()
        for (metric in metrics) {
            query_url = paste0(BASE_URL, "/api/datasets/:persistentId/makeDataCount/", 
                               metric, "?persistentId=", dDOI)
            
            response = httr::GET(query_url, 
                                 httr::add_headers("X-Dataverse-key"=API_TOKEN))
            
            if (httr::status_code(response) == 200) {
                metric_value = unlist(httr::content(response,
                                                    "parsed")$data)
            } else {
                warning(paste0(dDOI, " - ", metric, " : ",
                               httr::status_code(response), " ",
                               httr::content(response, "text")))
                metric_value = NA
            }
            results_tmp = c(results_tmp, metric_value)
        }
        # results_tmp = as.numeric(results_tmp)
        if ("message" %in% names(results_tmp)) {
            results_tmp = c(viewsTotal=NA, viewsUnique=NA,
                            downloadsTotal=NA, downloadsUnique=NA)
            
        }
        results_tmp = c(dataset_DOI=dDOI, results_tmp)
        results_tmp = dplyr::tibble(!!!results_tmp)
        results = dplyr::bind_rows(results, results_tmp)

        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : metrics for dataset ", convert_DOI_to_URL(dDOI), " retrieved"))
    }
    
    results = dplyr::mutate(results,
                            dplyr::across(.cols=metrics,
                                          .fns=as.numeric))
    return (results)
}


#' @title get_datasets_citation
#' @description Retrieves formatted citations for a selection of datasets using their DOI. Citations are cleaned from HTML entities and UNF codes.
#' @param dataset_DOI A vector of character strings representing the DOI of datasets.
#' @param BASE_URL A character string for the base URL of the Dataverse API.
#' @param API_TOKEN A character string for the API token required to authenticate the request.
#' @param clean_html If `TRUE`, decodes HTML entities (e.g., &eacute; to é). Defaults to `TRUE`.
#' @param remove_unf If `TRUE`, removes the UNF code at the end of citations. Defaults to `TRUE`.
#' @param replace_draft_version If `TRUE`, replaces "DRAFT VERSION" with "V1". Defaults to `TRUE`.
#' @param verbose If `FALSE`, no processing information is displayed. Defaults to `TRUE`.
#' @return A tibble containing dataset DOI and formatted citation.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = c("doi:10.57745/LNBEGZ")
#' get_datasets_citation(dataset_DOI)
#' 
#' # Keep original DRAFT VERSION
#' get_datasets_citation(dataset_DOI, replace_draft_version=FALSE)
#' 
#' # Keep HTML entities and UNF code
#' get_datasets_citation(dataset_DOI, clean_html=FALSE, remove_unf=FALSE)
#' }
#' @seealso
#' - [Native API documentation](https://guides.dataverse.org/en/latest/api/native-api.html#citation-api)
#' @md
#' @export
get_datasets_citation = function(dataset_DOI,
                                 BASE_URL=Sys.getenv("BASE_URL"),
                                 API_TOKEN=Sys.getenv("API_TOKEN"),
                                 clean_html=TRUE,
                                 remove_unf=TRUE,
                                 replace_draft_version=FALSE,
                                 verbose=TRUE) {
    results = dplyr::tibble()
    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        citation_value = NA
        
        # Essayer d'abord avec :latest (dataset publié)
        for (version in c("latest", "draft")) {
            query_url = paste0(
                BASE_URL,
                "/api/datasets/:persistentId/versions/:", version, 
                "/citation?persistentId=",
                utils::URLencode(dDOI, reserved=TRUE)
            )
            
            response = httr::GET(query_url,
                                 httr::add_headers("Accept"="application/json",
                                                   "X-Dataverse-key"=API_TOKEN))
            
            if (httr::status_code(response) == 200) {
                json_content = httr::content(response, "parsed",
                                              simplifyVector=TRUE)
                citation_value = json_content$data$message
                break  # Citation trouvée, on sort de la boucle
            }
        }
        
        if (is.na(citation_value)) {
            warning(paste0(
                dDOI, " - citation not found for the latest and draft versions: ",
                httr::status_code(response), " ",
                httr::content(response, "text")
            ))
        } else {
            # Nettoyer la citation
            if (clean_html) {
                # Décoder les entités HTML
                citation_value = xml2::xml_text(xml2::read_html(
                    paste0("<p>", citation_value, "</p>")
                ))
            }
            
            if (remove_unf) {
                # Supprimer le code UNF et tout ce qui suit
                # Pattern: , UNF:6:... [fileUNF] à la fin
                citation_value = sub(",?\\s*UNF:[^\\[]*\\[fileUNF\\]\\s*$", "", citation_value)
                # Aussi supprimer juste le UNF code s'il apparaît autrement
                citation_value = sub(",?\\s*UNF:[^,]*$", "", citation_value)
            }
            
            if (replace_draft_version) {
                citation_value = gsub("DRAFT VERSION", "V1",
                                      citation_value)
            }
            
            # Nettoyer les espaces multiples et trim
            citation_value = gsub("\\s+", " ", citation_value)
            citation_value = trimws(citation_value)
        }
        
        results_tmp = dplyr::tibble(
            dataset_DOI=dDOI,
            citation=citation_value
        )
        results = dplyr::bind_rows(results, results_tmp)
        
        if (verbose) {
            message(paste0(
                round(i / nDOI * 100, 1),
                "% : citation for dataset ",
                convert_DOI_to_URL(dDOI),
                " retrieved"
            ))
        }
    }
    return(results)
}


#' @title create_datasets
#' @description Create new datasets in a specified dataverse for a selection of metadata JSON file. See [generate_metadata_json()] in order to generate efficiently metadata JSON file.
#' @param dataverse A character string specifying the name of the dataverse in which to create datasets.
#' @param metadata_json_path A vector of character string for the paths of JSON files containing the datasets metadata.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return The function returns DOI of the newly created datasets as a vector of character string.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataverse = "inrae"
#' metadata_json_path = "path/to/read/metadata.json"
#' create_datasets(dataverse, metadata_json_path)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#create-a-dataset-in-a-dataverse) <https://guides.dataverse.org/en/5.3/api/native-api.html#create-a-dataset-in-a-dataverse>
#' @md
#' @export
create_datasets = function(dataverse,
                           metadata_json_path,
                           BASE_URL=Sys.getenv("BASE_URL"),
                           API_TOKEN=Sys.getenv("API_TOKEN"),
                           verbose=TRUE) {

    dataset_DOI = c()
    nDOI = length(metadata_json_path)
    
    for (i in 1:nDOI) {
        mpath = metadata_json_path[i]
        
        mjson = jsonlite::fromJSON(mpath,
                                   simplifyDataFrame=FALSE,
                                   simplifyVector=FALSE)

        create_url = paste0(BASE_URL, "/api/dataverses/",
                            dataverse, "/datasets")
        response = httr::POST(create_url,
                              httr::add_headers("X-Dataverse-key"=API_TOKEN),
                              body=mjson,
                              encode="json") 

        if (httr::status_code(response) != 201) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }

        dataset = httr::content(response, "parsed")
        dDOI = dataset$data$persistentId
        dataset_DOI = c(dataset_DOI, dDOI)

        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : dataset ", convert_DOI_to_URL(dDOI), " created"))
    }
    return (dataset_DOI)
}


#' @title convert_DOI_to_ID
#' @description Convert a dataset DOI (persistentId) to the internal Dataverse numeric dataset ID.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A numeric vector of dataset IDs corresponding to the DOIs.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' convert_DOI_to_ID("doi:10.57745/XXXXXX")
#' }
#' @md
#' @export
convert_DOI_to_ID = function(dataset_DOI,
                             BASE_URL=Sys.getenv("BASE_URL"),
                             API_TOKEN=Sys.getenv("API_TOKEN"),
                             verbose=TRUE) {

    dataset_ID = c()
    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]

        convert_url = paste0(BASE_URL,
                             "/api/datasets/:persistentId/?persistentId=",
                             dDOI)
        response = httr::GET(convert_url,
                             httr::add_headers("X-Dataverse-key"=API_TOKEN))
        
        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }

        content = httr::content(response, "parsed")
        dID = content$data$id
        dataset_ID = c(dataset_ID, dID)

        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : dataset DOI ", convert_DOI_to_URL(dDOI), " converted"))
    }
    return (dataset_ID)
}


#' @title move_datasets
#' @description Move one or more datasets from their current Dataverse collection to another Dataverse collection (superuser or authorized user only).
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param target_dataverse A character string giving the alias of the destination Dataverse.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' move_datasets(dataset_ID=12345,
#'               target_dataverse="new_dataverse")
#' }
#' @md
#' @export
move_datasets = function(dataset_DOI,
                         target_dataverse,
                         BASE_URL=Sys.getenv("BASE_URL"),
                         API_TOKEN=Sys.getenv("API_TOKEN"),
                         verbose=TRUE) {

    dataverse_url = paste0(BASE_URL, "/dataverse/", target_dataverse)
    
    nDOI = length(dataset_DOI)

    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        dID = convert_DOI_to_ID(dDOI,
                                BASE_URL=BASE_URL,
                                API_TOKEN=API_TOKEN,
                                verbose=FALSE)

        move_url = paste0(BASE_URL,
                          "/api/datasets/", dID,
                          "/move/", target_dataverse,
                          "?forceMove=true")
        response = httr::POST(move_url,
                              httr::add_headers("X-Dataverse-key"=API_TOKEN))

        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }
        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : dataset DOI ", convert_DOI_to_URL(dDOI), " moved in ", dataverse_url))
    }
}


get_datasets_metadata_call = function(dataset_DOI,
                                      BASE_URL=Sys.getenv("BASE_URL"),
                                      API_TOKEN=Sys.getenv("API_TOKEN")) {


    api_url = paste0(BASE_URL, "/api/datasets/:persistentId/?persistentId=", dataset_DOI)
    response = httr::GET(api_url, httr::add_headers("X-Dataverse-key"=API_TOKEN))
    
    if (httr::status_code(response) != 200) {
        stop(paste0(httr::status_code(response), " ",
                    httr::content(response, "text")))
    }

    response_content = httr::content(response, as="text",
                                     encoding="UTF-8")
    dataset = jsonlite::fromJSON(response_content,
                                 simplifyDataFrame=FALSE,
                                 simplifyVector=TRUE)
    metadata_json = dataset$data[c("metadataLanguage",
                                   "latestVersion")]

    return (metadata_json)
}


#' @title get_datasets_metadata
#' @description Retrieves metadata for a selection of dataset. See [convert_metadata_to_yml()] in order to convert metadata extracted by this function to R parameterisation file.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param metadata_json_path A vector of character string for the paths of JSON files containing the datasets metadata to write.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param overwrite A logical value indicating whether to overwrite an existing metadata file. Defaults to FALSE.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A list containing the datasets metadata.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' metadata_json_path = "path/to/write/metadata.json"
#' modify_datasets(dataset_DOI, metadata_json_path)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#get-json-representation-of-a-dataset) <https://guides.dataverse.org/en/5.3/api/native-api.html#get-json-representation-of-a-dataset>
#' @md
#' @export
get_datasets_metadata = function(dataset_DOI,
                                 metadata_json_path,
                                 BASE_URL=Sys.getenv("BASE_URL"),
                                 API_TOKEN=Sys.getenv("API_TOKEN"),
                                 overwrite=FALSE,
                                 verbose=TRUE) {

    metadata_list = list()
    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        mpath = metadata_json_path[i]

        metadata_json =
            get_datasets_metadata_call(dDOI,
                                       BASE_URL=BASE_URL,
                                       API_TOKEN=API_TOKEN)
        if (file.exists(mpath) & !overwrite) {
            message (paste0("Metadata file already exists in ",
                            mpath))
        } else {
            write(jsonlite::toJSON(metadata_json,
                                   pretty=TRUE,
                                   auto_unbox=TRUE), mpath)
        }
        
        if (verbose) message(paste0(round(i/nDOI*100, 1),
                                    "% : dataset metadata ",
                                    convert_DOI_to_URL(dDOI),
                                    " retrieved in ",
                                    mpath))
    }
}


#' @title modify_datasets
#' @description Modify datasets metadata from a selection of metadata JSON file. See [generate_metadata_json()] in order to generate efficiently metadata JSON file.
#' @param dataverse A character string specifying the name of the dataverse in which to create datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param metadata_json_path A vector of character string for the paths of JSON files containing the datasets metadata.
#' @param wait_time An integer for the time in seconds to wait between requests. By default, 2 seconds.
#' @param n_retries An integer for the maximum number of retries to reach dataverse server. By default, 3 retries.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' metadata_json_path = "path/to/read/metadata.json"
#' modify_datasets("inrae", dataset_DOI, metadata_json_path)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#update-metadata-for-a-dataset) <https://guides.dataverse.org/en/5.3/api/native-api.html#update-metadata-for-a-dataset>
#' @md
#' @export
modify_datasets = function(dataverse,
                           dataset_DOI,
                           metadata_json_path,
                           wait_time=2,
                           n_retries=3,
                           BASE_URL=Sys.getenv("BASE_URL"),
                           API_TOKEN=Sys.getenv("API_TOKEN"),
                           verbose=TRUE) {

    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        mpath = metadata_json_path[i]
        
        mjson = jsonlite::fromJSON(mpath,
                                   simplifyDataFrame=FALSE,
                                   simplifyVector=FALSE)
        modify_url = paste0(BASE_URL,
                            "/api/datasets/:persistentId/versions/:draft?persistentId=",
                            dDOI)
        response = httr::PUT(modify_url,
                             httr::add_headers("X-Dataverse-key"=API_TOKEN),
                             body=mjson$datasetVersion,
                             encode="json")

        attempt = 0
        while (httr::status_code(response) == 500 &
               httr::content(response, "text") == "{}" &
               attempt < n_retries) {
                   response = httr::PUT(modify_url,
                                        httr::add_headers("X-Dataverse-key"=API_TOKEN),
                                        body=mjson$datasetVersion,
                                        encode="json")
                   attempt = attempt + 1
                   Sys.sleep(wait_time)
               }
        if (attempt >= n_retries) {
            stop("Dataverse server returned empty response after ",
                 n_retries, " attempts.")
        }
        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }

        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : dataset ", convert_DOI_to_URL(dDOI), " modified"))
        Sys.sleep(wait_time)
    }
}


#' @title add_datasets_files
#' @description This function uploads files to a dataset.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param file_paths A vector of character string of paths of the files that needs to be uploaded. If you want to conserve a directory structure, set the name of each file path to the directory name wanted. If `dataset_DOI` contains more than one dataset DOI, `file_paths` needs to be a list of vector of character string, each vector of this list will be associated to each dataset identified in `dataset_DOI`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param timeout An integer to set the number of second before timeout of the request. By default, 600.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A character vector containing the paths of the files that could not be uploaded, if any.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' paths = c("path/to/file.csv", other/path/to/README.txt)
#' not_added = add_datasets_files(dataset_DOI, paths)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#add-a-file-to-a-dataset) <https://guides.dataverse.org/en/5.3/api/native-api.html#add-a-file-to-a-dataset>
#' @md
#' @export
add_datasets_files = function(dataset_DOI, file_paths,
                              BASE_URL=Sys.getenv("BASE_URL"),
                              API_TOKEN=Sys.getenv("API_TOKEN"),
                              timeout=600,
                              verbose=TRUE) {

    if (!is.list(file_paths)) {
        file_paths = list(file_paths)
    }

    not_added = list()
    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : files addition for dataset ", convert_DOI_to_URL(dDOI)))
        
        url = paste0(BASE_URL,
                     '/api/datasets/:persistentId/add?persistentId=',
                     dDOI)

        not_added_tmp = c()
        nFiles = length(file_paths[[i]])
        
        for (j in 1:nFiles) {
            file_path = file_paths[[i]][j]
            directory_label = names(file_paths[[i]])[j]
            
            if (is.null(directory_label)) {
                directory_label = ""
            }

            # tabIngest = grepl("\\.tab$|\\.csv$|\\.tsv$", file_path, ignore.case=TRUE)
            # json_data = list(
            #     description = "",
            #     directoryLabel = directory_label,
            #     restrict = "false",
            #     tabIngest = tolower(as.character(tabIngest))
            # )
            json_data = list(
                description = "",
                directoryLabel = directory_label,
                restrict = "false",
                tabIngest = "true"
            )
            start_time = Sys.time()
            response =
                httr::POST(url,
                           httr::add_headers("X-Dataverse-key" = API_TOKEN),
                           body=list(
                               file = httr::upload_file(file_path),
                               jsonData=I(jsonlite::toJSON(json_data, auto_unbox=TRUE))
                           ),
                           encode="multipart",
                           httr::timeout(timeout))
            
            end_time = Sys.time()
            elapsed_time = as.numeric(difftime(end_time, start_time, units = "secs"))
            file_size = file.info(file_path)$size / (1024^2) # in MB
            upload_speed = file_size / elapsed_time

            paste0("Uploaded ", round(file_size, 2), " MB in ", round(elapsed_time, 2), " seconds (", round(upload_speed, 2), " MB/s)")
            
            if (httr::status_code(response) != 200) {
                not_added_tmp = c(not_added_tmp, file_path)
                names(not_added_tmp)[length(not_added_tmp)] = j
                warning(paste0("file ", j, " : ", file_path, "\n",
                               httr::status_code(response), " ",
                               httr::content(response, "text")))
            }
            if (verbose) message(paste0(" - ", round(j/nFiles*100, 1),
                                        "% : file ", file_path, " of ",
                                        round(file_size, 2), " MB added in ",
                                        round(elapsed_time, 2), " seconds (",
                                        round(upload_speed, 2), " MB/s)"))
        }
        not_added = append(not_added, list(not_added_tmp))
    }
    return (not_added)
}


#' @title list_datasets_files
#' @description Retrieves files informations of a selection of datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @return A [tibble][dplyr::tibble()] containing files information.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' files = list_datasets_files(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R>
#' -  [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#list-files-in-a-dataset) <https://guides.dataverse.org/en/5.3/api/native-api.html#list-files-in-a-dataset>
#' @md
#' @export
list_datasets_files = function(dataset_DOI,
                               BASE_URL=Sys.getenv("BASE_URL"),
                               API_TOKEN=Sys.getenv("API_TOKEN")) {

    files = dplyr::tibble()
    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        
        api_url = paste0(BASE_URL,
                         "/api/datasets/:persistentId/?persistentId=",
                         dDOI)
        response = httr::GET(api_url,
                             httr::add_headers("X-Dataverse-key"=API_TOKEN))

        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }
        
        response_content = httr::content(response, as="text",
                                         encoding="UTF-8")
        dataset_info = jsonlite::fromJSON(response_content)
        files_tmp = dataset_info$data$latestVersion$files
        if ("description" %in% names(files_tmp)) {
            files_tmp = dplyr::select(files_tmp, -description)
        }
        if ("categories" %in% names(files_tmp$dataFile)) {
            files_tmp$dataFile = dplyr::select(files_tmp$dataFile, -categories)
        }
        files_tmp = tidyr::unnest(files_tmp, cols=c(dataFile))
        files_tmp = dplyr::rename(files_tmp, file_DOI=persistentId)
        files_tmp$dataset_DOI = dDOI
        files_tmp = dplyr::relocate(files_tmp, dataset_DOI,
                                    .before=dplyr::everything())
        
        files = dplyr::bind_rows(files, files_tmp)
    }
    return (files)
}


#' @title rename_datasets_files
#' @description Renames a file based on their DOI.
#' @param file_DOI A vector of character string of the DOI of files to be processed.
#' @param new_name A vector of character string representing the new filename.
#' @param is_DOI_ID If the dataset is not published yet, the DOI of the file does not exist, so `file_DOI` needs to be the file id of the database instead of a DOI. So if `TRUE`, `file_DOI` is `id` from the results of [list_datasets_files()], elsewhere if `FALSE`, `file_DOI` is actual file DOI. Default, `FALSE`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # In general
#' file_DOI = "doi:10.57745/QB73Q0"
#' rename_datasets_files(file_DOI, new_name="LICENCE_Etalab.pdf")
#' 
#' # A more complexe example when the dataset is a DRAFT
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' files = list_datasets_files(dataset_DOI)
#' licence = dplyr::filter(files, grepl("LICENCE", label))
#' rename_datasets_files(file_DOI=licence$id,
#'                       new_name="LICENCE_Etalab.pdf",
#'                       is_DOI_ID=TRUE)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#updating-file-metadata) <https://guides.dataverse.org/en/5.3/api/native-api.html#updating-file-metadata>
#' @md
#' @export
rename_datasets_files = function(file_DOI, new_name,
                                 is_DOI_ID=FALSE,
                                 BASE_URL=Sys.getenv("BASE_URL"),
                                 API_TOKEN=Sys.getenv("API_TOKEN"),
                                 verbose=TRUE) {

    nFiles = length(file_DOI)
    
    for (i in 1:nFiles) {
        fDOI = file_DOI[i]
        label = new_name[i]

        if (is_DOI_ID) {
            api_url = paste0(BASE_URL, "/api/files/",
                             fDOI, "/metadata")
        } else {
            api_url = paste0(BASE_URL, "/api/files/:persistentId/metadata?persistentId=",
                             fDOI)
        }
        
        json_body = jsonlite::toJSON(list(label=label), auto_unbox=TRUE)
        
        response = httr::POST(url=api_url,
                              httr::add_headers("X-Dataverse-key"=API_TOKEN),
                              body=list(jsonData=json_body),
                              encode="multipart")
        
        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }
        if (verbose) message(paste0(round(i/nFiles*100, 1), "% : file ", convert_DOI_to_URL(fDOI), " renamed"))
    }
}


#' @title download_some_datasets_files
#' @description Download specific files based on their DOI or ID. This function allows selective file downloads when you don't want to download all files from a dataset.
#' @param file_DOI A vector of character strings representing the DOI (or ID if `is_DOI_ID=TRUE`) of files to be downloaded.
#' @param save_paths A vector of character strings representing the local file paths where files should be saved. Must have the same length as `file_DOI`.
#' @param is_DOI_ID If the dataset is not published yet, the DOI of the file does not exist, so `file_DOI` needs to be the file id of the database instead of a DOI. If `TRUE`, `file_DOI` is `id` from the results of [list_datasets_files()], otherwise if `FALSE`, `file_DOI` is actual file DOI. Defaults to `FALSE`.
#' @param overwrite A logical value indicating whether to overwrite existing files. Defaults to `FALSE`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return Invisible NULL. Files are downloaded to the specified paths.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # Download a single file with published DOI
#' file_DOI = "doi:10.57745/QB73Q0"
#' download_some_datasets_files(file_DOI, save_paths="LICENCE.pdf")
#' 
#' # Download multiple specific files
#' file_DOI = c("doi:10.57745/QB73Q0", "doi:10.57745/AUTRE")
#' save_paths = c("LICENCE.pdf", "README.md")
#' download_some_datasets_files(file_DOI, save_paths)
#' 
#' # Download files from a DRAFT dataset using file IDs
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' files = list_datasets_files(dataset_DOI)
#' licence = dplyr::filter(files, grepl("LICENCE", label))
#' download_some_datasets_files(file_DOI=licence$id,
#'                              save_paths="LICENCE_Etalab.pdf",
#'                              is_DOI_ID=TRUE)
#' 
#' # Download with custom directory structure
#' file_DOI = "doi:10.57745/QB73Q0"
#' download_some_datasets_files(file_DOI, save_paths="data/licences/LICENCE.pdf")
#' }
#' @seealso
#' - [download_datasets_files()] for downloading all files from one or multiple datasets
#' - [list_datasets_files()] for listing available files in a dataset
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#accessing-downloading-files) <https://guides.dataverse.org/en/5.3/api/native-api.html#accessing-downloading-files>
#' @md
#' @export
download_some_datasets_files = function(file_DOI,
                                        save_paths,
                                        is_DOI_ID=FALSE,
                                        overwrite=FALSE,
                                        BASE_URL=Sys.getenv("BASE_URL"),
                                        API_TOKEN=Sys.getenv("API_TOKEN"),
                                        verbose=TRUE) {
    
    nFiles = length(file_DOI)
    nPaths = length(save_paths)
    
    # Vérifier la cohérence des longueurs
    if (nFiles != nPaths) {
        stop(paste0("file_DOI and save_paths must have the same length. ",
                    "Got ", nFiles, " file(s) and ", nPaths, " path(s)."))
    }
    
    for (i in 1:nFiles) {
        fDOI = file_DOI[i]
        save_path = save_paths[i]
        
        # Créer le dossier parent si nécessaire
        save_dir = dirname(save_path)
        if (!dir.exists(save_dir) && save_dir != ".") {
            dir.create(save_dir, recursive=TRUE)
        }
        
        # Construire l'URL de l'API
        if (is_DOI_ID) {
            api_url = paste0(BASE_URL, "/api/access/datafile/", fDOI)
        } else {
            api_url = paste0(BASE_URL, "/api/access/datafile/:persistentId/?persistentId=", fDOI)
        }
        
        # Télécharger le fichier
        response = httr::GET(api_url, 
                             httr::add_headers("X-Dataverse-key"=API_TOKEN),
                             httr::write_disk(save_path, overwrite=overwrite))
        
        if (httr::status_code(response) != 200) {
            stop(paste0("Failed to download file ", 
                        ifelse(is_DOI_ID, fDOI, convert_DOI_to_URL(fDOI)),
                        ". Error: ", httr::status_code(response), " - ",
                        httr::content(response, "text")))
        }
        
        if (verbose) {
            message(paste0(round(i/nFiles*100, 1), "% : file ", 
                          ifelse(is_DOI_ID, fDOI, convert_DOI_to_URL(fDOI)), 
                          " saved in ", save_path))
        }
    }
    
    return (NULL)
}


#' @title download_datasets_files
#' @description Download all files from one or multiple datasets. Files are automatically organized in subdirectories named after sanitized dataset DOIs.
#' @param dataset_DOI A vector of character string of dataset DOI(s). All files from each dataset will be downloaded.
#' @param dirpath A character string representing the base local directory path where files should be saved. Defaults to `"dataverse_files"`. Subdirectories will be created for each dataset based on sanitized dataset DOIs.
#' @param overwrite A logical value indicating whether to overwrite existing files. Defaults to FALSE.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # Download all files from a single dataset
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' download_datasets_files(dataset_DOI)
#' # Files saved in: dataverse_files/doi_10-57745_LNBEGZ/
#' 
#' # Download all files from multiple datasets
#' dataset_DOI = c("doi:10.57745/LNBEGZ", "doi:10.57745/TGYZ8L")
#' download_datasets_files(dataset_DOI)
#' # Files saved in: dataverse_files/doi_10-57745_LNBEGZ/ and dataverse_files/doi_10-57745_TGYZ8L/
#' 
#' # With custom save directory
#' download_datasets_files(dataset_DOI, dirpath="my_files")
#' 
#' # Works with DRAFT datasets too
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' download_datasets_files(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#accessing-downloading-files) <https://guides.dataverse.org/en/5.3/api/native-api.html#accessing-downloading-files>
#' @md
#' @export
download_datasets_files = function(dataset_DOI,
                                   dirpath="dataverse_files",
                                   overwrite=FALSE,
                                   BASE_URL=Sys.getenv("BASE_URL"),
                                   API_TOKEN=Sys.getenv("API_TOKEN"),
                                   verbose=TRUE) {
    
    nDatasets = length(dataset_DOI)
    total_files = 0
    files_downloaded = 0
    
    # Compter le nombre total de fichiers pour la progression
    if (verbose) {
        for (dDOI in dataset_DOI) {
            files_info = list_datasets_files(dDOI, BASE_URL, API_TOKEN)
            total_files = total_files + nrow(files_info)
        }
    }

    # Télécharger les fichiers de chaque dataset
    for (i in 1:nDatasets) {
        dDOI = dataset_DOI[i]
        
        # Récupérer les métadonnées des fichiers
        files_info = list_datasets_files(dDOI, BASE_URL, API_TOKEN)
        
        if (nrow(files_info) == 0) {
            if (verbose) {
                message(paste0("No files found in dataset ", convert_DOI_to_URL(dDOI)))
            }
            next
        }
        
        # Créer le dossier pour ce dataset
        sanitized_doi = sanitize_doi(dDOI)
        dataset_dir = file.path(dirpath, sanitized_doi)
        if (!dir.exists(dataset_dir)) {
            dir.create(dataset_dir, recursive=TRUE)
        }

        # Télécharger chaque fichier du dataset
        for (j in 1:nrow(files_info)) {
            file_id = files_info$id[j]
            file_label = files_info$label[j]
            save_path = file.path(dataset_dir, file_label)
            
            api_url = paste0(BASE_URL, "/api/access/datafile/", file_id)
            
            response = httr::GET(api_url, 
                                 httr::add_headers("X-Dataverse-key"=API_TOKEN),
                                 httr::write_disk(save_path, overwrite=overwrite))
            
            if (httr::status_code(response) != 200) {
                warning(paste0("Failed to download file ", file_label, 
                              " (ID: ", file_id, ") from dataset ", dDOI,
                              ". Error: ", httr::status_code(response), " - ",
                              httr::content(response, "text")))
            } else {
                files_downloaded = files_downloaded + 1
                if (verbose) {
                    message(paste0(round(files_downloaded / total_files * 100, 1), 
                                  "% : file ", file_label, 
                                  " from dataset ", convert_DOI_to_URL(dDOI),
                                  " saved in ", save_path))
                }
            }
        }
    }
    
    if (verbose) {
        message(paste0("Download complete: ", files_downloaded, " file(s) downloaded"))
    }
}


#' @title delete_datasets_files
#' @description Delete files based on their DOI.
#' @param file_DOI A vector of character string of the DOI of files to be processed.
#' @param is_DOI_ID If the dataset is not published yet, the DOI of the file does not exist, so `file_DOI` needs to be the file id of the database instead of a DOI. So if `TRUE`, `file_DOI` is `id` from the results of [list_datasets_files()], elsewhere if `FALSE`, `file_DOI` is actual file DOI. Default, `FALSE`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # In general
#' file_DOI = "doi:10.57745/QB73Q0"
#' delete_datasets_files(file_DOI)
#'
#' # A more complexe example when the dataset is a DRAFT
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' files = list_datasets_files(dataset_DOI)
#' licence = dplyr::filter(files, grepl("LICENCE", label))
#' delete_datasets_files(file_DOI=licence$id,
#'                       is_DOI_ID=TRUE)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/DRYvER/modify_README.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#files) <https://guides.dataverse.org/en/5.3/api/native-api.html#files>
#' @md
#' @export
delete_datasets_files = function(file_DOI,
                                 is_DOI_ID=FALSE,
                                 BASE_URL=Sys.getenv("BASE_URL"),
                                 API_TOKEN=Sys.getenv("API_TOKEN"),
                                 verbose=TRUE) {

    nFiles = length(file_DOI)
    
    for (i in 1:nFiles) {
        fDOI = file_DOI[i]

        if (is_DOI_ID) {
            delete_url = paste0(BASE_URL, "/api/files/", fDOI)
        } else {
            delete_url = paste0(BASE_URL, "/api/files/:persistentId/?persistentId=", fDOI)
        }
        
        response = httr::DELETE(delete_url,
                                httr::add_headers("X-Dataverse-key"=API_TOKEN))
        
        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }
        if (verbose) message(paste0(round(i/nFiles*100, 1), "% : file ", convert_DOI_to_URL(fDOI), " deleted"))
    }
}


#' @title delete_all_datasets_files
#' @description Delete all files from a selection of datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' delete_all_datasets_files(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#files) <https://guides.dataverse.org/en/5.3/api/native-api.html#files>
#' @md
#' @export
delete_all_datasets_files = function(dataset_DOI,
                                     BASE_URL=Sys.getenv("BASE_URL"),
                                     API_TOKEN=Sys.getenv("API_TOKEN"),
                                     verbose=TRUE) {

    nDOI = length(dataset_DOI)
    
    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : files deletion for dataset ", convert_DOI_to_URL(dDOI)))
        
        files = list_datasets_files(dataset_DOI=dDOI,
                                    BASE_URL=BASE_URL,
                                    API_TOKEN=API_TOKEN)
        nFiles = nrow(files)
        
        for (j in 1:nFiles) {
            file = files[j, ]
            fID = file$id
            fDOI = file$file_DOI
            
            delete_datasets_files(file_DOI=fID,
                                  is_DOI_ID=TRUE,
                                  BASE_URL=BASE_URL,
                                  API_TOKEN=API_TOKEN,
                                  verbose=FALSE)

            if (verbose) message(paste0(" - ", round(j/nFiles*100, 1), "% : file ", convert_DOI_to_URL(fDOI), " deleted"))
            
            # delete_url = paste0(BASE_URL, "/api/files/", file_id)
            # response = httr::DELETE(delete_url,
            # httr::add_headers("X-Dataverse-key"=API_TOKEN))
            
            # if (httr::status_code(response) == 200) {
            # print(paste0(i, ": ", file$id, " -> ok"))
            # } else {
            # print(paste0(i, ": ", file$id, " -> error ",
            # httr::status_code(response), " ",
            # httr::content(response, "text")))
            # }
        }
    }
}


#' @title publish_datasets
#' @description Publish a selection of datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param type A character string specifying the type of publication. Use `"major"` if at least a file as been modified of supressed, if only metadata have changed, use `"minor"`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' publish_datasets(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#publish-a-dataset) <https://guides.dataverse.org/en/5.3/api/native-api.html#publish-a-dataset>
#' @md
#' @export
publish_datasets = function(dataset_DOI, type="major",
                            BASE_URL=Sys.getenv("BASE_URL"),
                            API_TOKEN=Sys.getenv("API_TOKEN"),
                            verbose=TRUE) {

    nDOI = length(dataset_DOI)

    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        
        publish_url = paste0(BASE_URL, "/api/datasets/:persistentId/actions/:publish?persistentId=",
                             dDOI, "&type=", type)
        response = httr::POST(publish_url,
                              httr::add_headers("X-Dataverse-key"=API_TOKEN))
        
        if (httr::status_code(response) != 200) {
            stop(paste0(httr::status_code(response), " ",
                        httr::content(response, "text")))
        }
        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : dataset ", convert_DOI_to_URL(dDOI), " published"))
    }
}


#' @title delete_datasets
#' @description Delete a selection of unpublished datasets.
#' @param dataset_DOI A vector of character string representing the DOI of datasets that will be process.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' delete_datasets(dataset_DOI)
#' }
#' @seealso
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' - [R example in context](https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R) <https://github.com/lou-heraut/dataverseuR_toolbox/blob/main/Explore2/post_hydrological_projection.R>
#' - [Native API documentation](https://guides.dataverse.org/en/5.3/api/native-api.html#delete-unpublished-dataset) <https://guides.dataverse.org/en/5.3/api/native-api.html#delete-unpublished-dataset>
#' @md
#' @export
delete_datasets = function(dataset_DOI,
                           BASE_URL=Sys.getenv("BASE_URL"),
                           API_TOKEN=Sys.getenv("API_TOKEN"),
                           verbose=TRUE) {
    
    nDOI = length(dataset_DOI)

    for (i in 1:nDOI) {
        dDOI = dataset_DOI[i]
        
        delete_url = paste0(BASE_URL, "/api/datasets/:persistentId/?persistentId=", dDOI)
        response = httr::DELETE(delete_url,
                                httr::add_headers("X-Dataverse-key"=API_TOKEN))
        
        if (httr::status_code(response) != 200) {
            warning(paste0(httr::status_code(response), " ",
                           httr::content(response, "text")))
        }
        if (verbose) message(paste0(round(i/nDOI*100, 1), "% : dataset ", convert_DOI_to_URL(dDOI), " deleted"))
    }
}
