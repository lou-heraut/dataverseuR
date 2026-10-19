


cut_line = function (line_title, line_content, indent=0, nchar_line=80) {
    if (nchar(line_title) > 0) {
        if (grepl("[-]", line_title)) {
            line_title = paste0(strrep(" ", indent), "- ")
        } else {
            line_title = paste0(strrep(" ", indent), line_title, ": ")
        }
    }

    result = paste0(line_title, line_content) 
    if (nchar(result) > nchar_line) {
        line_content = paste0(paste0(strrep(" ", indent), "  ",
                                     strwrap(line_content,
                                             width=nchar_line-2-indent)),
                              collapse="\n")
        result = paste0(line_title, ">\n",
                        line_content) 
    }
    return (result)
}


format_yml = function (line_title, line_content, indent=0, nchar_line=80) {

    n_title = length(line_title)
    n_content = length(line_content)

    if (n_title == 1 & n_content == 1) {
        result = cut_line(line_title, line_content, indent, nchar_line)
    } else if (n_title == 1 & n_content > 1) {
        result = paste0(strrep(" ", indent), line_title, ": ")
        for (i in 1:n_content) {
            l_content = line_content[i]
            l_content = cut_line("- ", l_content, indent+2, nchar_line)
            result = paste0(result, "\n", l_content)
        }
    } else if (n_title > 1 & n_title == n_content) {
        result = paste0(mapply(cut_line, line_title,
                               line_content, indent, nchar_line),
                        collapse="\n")
    } else {
        stop()
    }
    
    return (result)
}



get_info_dir = function(path) {
    paths = list.files(path,
                       recursive=TRUE,
                       all.files=FALSE,
                       full.names=TRUE)
    n_files = sum(file.info(paths)$isdir == FALSE, na.rm=TRUE)
    n_dirs = sum(file.info(paths)$isdir == TRUE, na.rm=TRUE)
    
    info = sprintf(
        "%d directory%s, %d file%s",
        n_dirs,
        ifelse(n_dirs == 1, "", "ies"),
        n_files,
        ifelse(n_files == 1, "", "s"))
    
    return (info)
}



#' @title clean_datasets_files
#' @description Clean and convert dataset files using ASHE::convert_tibble. Processes tabular files from specified datasets and saves cleaned versions in organized directories. By default, processes common tabular formats while excluding README and metadata files.
#' @param dataset_DOI A vector of character strings of dataset DOI(s). Files from each dataset will be cleaned.
#' @param dirpath A character string representing the base local directory path where original files are located and where cleaned files will be saved. Defaults to `"dataverse_files"`. Cleaned files will be saved in subdirectories named `{sanitized_doi}_cleaned`.
#' @param include_extensions A vector of character strings representing file extensions to include for cleaning. Defaults to `c("csv", "txt", "tab", "tsv", "dat")`. Extensions should be provided without the dot.
#' @param exclude_patterns A vector of character strings representing patterns to exclude from cleaning. Files matching any of these patterns (case-insensitive) will be skipped. Defaults to `c("readme", "license", "licence", "citation")`. Set to `NULL` to disable exclusion.
#' @param output_extension A character string representing the output file extension. Defaults to `".csv"`. The original extension will be replaced by this one.
#' @param overwrite A logical value indicating whether to overwrite existing files. Defaults to FALSE.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A list of results from ASHE::convert_tibble for each processed file, organized by dataset.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # Clean tabular files from a single dataset (default behavior)
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' clean_datasets_files(dataset_DOI)
#' # Processes: .csv, .txt, .tab, .tsv, .dat
#' # Excludes: files containing "readme", "license", "citation"
#' # Original files in: dataverse_files/doi_10-57745_LNBEGZ/
#' # Cleaned files in: dataverse_files/doi_10-57745_LNBEGZ_cleaned/
#' 
#' # Clean files from multiple datasets
#' dataset_DOI = c("doi:10.57745/LNBEGZ", "doi:10.57745/TGYZ8L")
#' clean_datasets_files(dataset_DOI)
#' 
#' # Only clean CSV files
#' clean_datasets_files(dataset_DOI, include_extensions="csv")
#' 
#' # Add custom exclusion patterns
#' clean_datasets_files(dataset_DOI, 
#'                      exclude_patterns=c("readme", "license", "metadata", "description"))
#' 
#' # Disable exclusions (process all matching extensions)
#' clean_datasets_files(dataset_DOI, exclude_patterns=NULL)
#' 
#' # Custom extensions and output format
#' clean_datasets_files(dataset_DOI, 
#'                      include_extensions=c("csv", "tsv"),
#'                      output_extension=".parquet")
#' 
#' # With custom directory
#' clean_datasets_files(dataset_DOI, dirpath="my_data")
#' }
#' @seealso
#' - [download_datasets_files()] for downloading dataset files
#' - [ASHE::convert_tibble()] for the underlying conversion function
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @md
#' @export
clean_datasets_files = function(dataset_DOI,
                                dirpath="dataverse_files",
                                include_extensions=c("csv", "txt", "tab"),
                                exclude_patterns=c("tmp", "readme", "license",
                                                   "licence", "citation"),
                                output_extension=".csv",
                                overwrite=FALSE,
                                verbose=TRUE) {
    
    nDatasets = length(dataset_DOI)
    all_results = list()
    # all_outdir = c()
    
    for (i in 1:nDatasets) {
        dDOI = dataset_DOI[i]
        sanitized_doi = sanitize_doi(dDOI)
        
        # Définir les chemins d'entrée et de sortie
        input_dir = file.path(dirpath, sanitized_doi)
        output_dir = file.path(dirpath, paste0(sanitized_doi, "_cleaned"))
        
        # Vérifier que le dossier d'entrée existe
        if (!dir.exists(input_dir)) {
            warning(paste0("Input directory does not exist: ", input_dir, 
                          ". Skipping dataset ", dDOI))
            next
        }
        
        # Créer le dossier de sortie
        if (!dir.exists(output_dir)) {
            dir.create(output_dir, recursive=TRUE)
        }
        
        # Lister tous les fichiers du dossier
        all_files = list.files(input_dir, full.names=TRUE)
        
        if (length(all_files) == 0) {
            if (verbose) {
                message(paste0("No files found in ", input_dir))
            }
            next
        }
        
        # Filtrer par extension
        file_extensions = tolower(tools::file_ext(all_files))
        include_mask = file_extensions %in% tolower(include_extensions)
        input_paths = all_files[include_mask]
        
        if (length(input_paths) == 0) {
            if (verbose) {
                message(paste0("No files with extensions [", 
                              paste(include_extensions, collapse=", "),
                              "] found in ", input_dir))
            }
            next
        }
        
        # Filtrer par patterns d'exclusion (case-insensitive)
        if (!is.null(exclude_patterns) && length(exclude_patterns) > 0) {
            file_basenames = tolower(basename(input_paths))
            exclude_mask = rep(FALSE, length(input_paths))
            
            for (pattern in exclude_patterns) {
                exclude_mask = exclude_mask | grepl(tolower(pattern), file_basenames)
            }
            
            excluded_files = input_paths[exclude_mask]
            input_paths = input_paths[!exclude_mask]
            
            if (verbose && length(excluded_files) > 0) {
                message(paste0("Excluded ", length(excluded_files), 
                              " file(s) matching exclusion patterns: ",
                              paste(basename(excluded_files), collapse=", ")))
            }
        }
        
        if (length(input_paths) == 0) {
            if (verbose) {
                message(paste0("No files remaining after applying exclusion filters for dataset ",
                              convert_DOI_to_URL(dDOI)))
            }
            next
        }
        
        # Créer les chemins de sortie
        output_paths = file.path(output_dir, basename(input_paths))
        
        # Remplacer l'extension
        if (!is.null(output_extension) && output_extension != "") {
            output_paths = sub("\\.[^.]*$", output_extension, output_paths)
        }
        
        if (verbose) {
            message(paste0("Processing ", length(input_paths), " file(s) from dataset ",
                           convert_DOI_to_URL(dDOI)))
        }
        
        results = mapply(ASHE::convert_tibble,
                         path=input_paths,
                         output_path=output_paths,
                         read_guess_sep=TRUE,
                         read_guess_text_encoding=TRUE,
                         overwrite=overwrite,
                         SIMPLIFY=FALSE)

        all_results[[dDOI]] = results
        # all_outdir[dDOI] = output_dir
        
        if (verbose) {
            message(paste0("Dataset ", convert_DOI_to_URL(dDOI), 
                          " cleaned: ", length(input_paths), 
                          " file(s) saved in ", output_dir))
        }
    }
    
    if (verbose && length(all_results) > 0) {
        total_files = sum(sapply(all_results, length))
        message(paste0("Cleaning complete: ", total_files, 
                      " file(s) processed across ", 
                      length(all_results), " dataset(s)"))
    }
    
    invisible(all_results)
}



#' @title create_datasets_README
#' @description Automatically generates README files for one or multiple datasets. Creates structured documentation including metadata, file descriptions, and column information for cleaned datasets.
#' @param dataset_DOI A vector of character strings of dataset DOI(s). A README will be created for each dataset.
#' @param dirpath A character string representing the base local directory path where cleaned datasets are located. Defaults to `"dataverse_files"`. README files will be created in subdirectories named `{sanitized_doi}_cleaned`.
#' @param file_pattern A character string representing the file pattern to document in the README. Defaults to `"*.csv"`. Use standard glob patterns (e.g., `"*.tsv"`, `"*"` for all files).
#' @param overwrite A logical value indicating whether to overwrite existing README files. Defaults to `FALSE`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return Invisible NULL. README files are created in the appropriate directories.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # Create README for a single dataset
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' create_datasets_README(dataset_DOI)
#' # README created in: dataverse_files/doi_10-57745_LNBEGZ_cleaned/README.txt
#' 
#' # Create READMEs for multiple datasets
#' dataset_DOI = c("doi:10.57745/LNBEGZ", "doi:10.57745/TGYZ8L")
#' create_datasets_README(dataset_DOI)
#' 
#' # With custom directory and file pattern
#' create_datasets_README(dataset_DOI, 
#'                        dirpath="my_data",
#'                        file_pattern="*.tsv")
#' 
#' # Overwrite existing README
#' create_datasets_README(dataset_DOI, overwrite=TRUE)
#' }
#' @note
#' The function uses a template README file included in the package. Column information sections are pre-filled with placeholders that need to be manually completed (description, long_name, unit, allowed_values).
#' @seealso
#' - [clean_datasets_files()] for cleaning dataset files before creating README
#' - [download_datasets_files()] for downloading dataset files
#' - [get_datasets_metadata()] for retrieving dataset metadata
#' - [get_datasets_citation()] for retrieving dataset citations
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @md
#' @export
create_datasets_README = function(dataset_DOI,
                                  dirpath="dataverse_files",
                                  file_pattern="*.csv",
                                  overwrite=FALSE,
                                  BASE_URL=Sys.getenv("BASE_URL"),
                                  API_TOKEN=Sys.getenv("API_TOKEN"),
                                  verbose=TRUE) {

    nDatasets = length(dataset_DOI)
    
    for (idx in 1:nDatasets) {
        dDOI = dataset_DOI[idx]

        sanitized_doi = sanitize_doi(dDOI)
        RDG_datadir = file.path(dirpath, paste0(sanitized_doi, "_cleaned"))
        README_path = file.path(RDG_datadir, "README.txt")
        
        # Vérifier que le dossier existe
        if (!dir.exists(RDG_datadir)) {
            warning(paste0("Directory does not exist: ", RDG_datadir, 
                          ". Skipping dataset ", dDOI))
            next
        }
        
        # Vérifier l'overwrite
        if (file.exists(README_path) && !overwrite) {
            warning(paste0("README already exists at ", README_path, 
                          " and overwrite is FALSE. Skipping dataset ", dDOI))
            next
        }
        
        if (verbose) {
            message(paste0("Creating README for dataset ", 
                          convert_DOI_to_URL(dDOI)))
        }
        
        # Récupérer les métadonnées
        metadata_json = get_datasets_metadata_call(dDOI,
                                                   BASE_URL=BASE_URL,
                                                   API_TOKEN=API_TOKEN)
        metadata_json_fields = metadata_json$latestVersion$metadataBlocks$citation$fields
        typeName = sapply(metadata_json_fields, "[[", "typeName")
        
        nchar_line = 80
        TODAY = Sys.Date()
        
        # Charger le template
        README_template_path = system.file("templates", "README_template_en.txt",
                                          package="dataverseuR")
        README = readLines(README_template_path)
        README = gsub("[{]TODAY[}]", TODAY, README)
        
        # Extraire les informations du dataset
        RDG_TITLE = metadata_json_fields[typeName == "title"][[1]]$value
        RDG_DOI = convert_DOI_to_URL(dDOI)
        RDG_CITATION = get_datasets_citation(dDOI, 
                                             BASE_URL=BASE_URL,
                                             API_TOKEN=API_TOKEN,
                                             replace_draft_version=TRUE,
                                             verbose=FALSE)$citation
        RDG_CONTACT_EMAIL = sapply(
            metadata_json_fields[typeName == "datasetContact"][[1]]$value,
            function(x) x$datasetContactEmail$value
        )
        
        # Gérer le cas où il n'y a pas de publication
        if (any(typeName == "publication")) {
            RDG_PUBLICATION = sapply(
                metadata_json_fields[typeName == "publication"][[1]]$value,
                function(x) x$publicationCitation$value
            )
        } else {
            RDG_PUBLICATION = "N/A"
        }
        
        # Remplir les champs du README
        title = format_yml("Dataset title", RDG_TITLE, 0, nchar_line)
        README = gsub("[{]TITLE[}]", title, README)
        
        doi = format_yml("DOI", RDG_DOI, 0, nchar_line)
        README = gsub("[{]DOI[}]", doi, README)
        
        citation = format_yml("Citation", RDG_CITATION, 0, nchar_line)
        README = gsub("[{]CITATION[}]", citation, README)
        
        email = format_yml("Contact email", RDG_CONTACT_EMAIL, 0, nchar_line)
        README = gsub("[{]EMAIL[}]", email, README)
        
        publication = format_yml("Related publication", RDG_PUBLICATION, 0, nchar_line)
        README = gsub("[{]PUBLICATION[}]", publication, README)
        
        # Créer l'arborescence
        tree = utils::capture.output(fs::dir_tree(RDG_datadir))
        tree[1] = "."
        tree = c(tree, get_info_dir(RDG_datadir))
        tree = paste0(tree, collapse="\n")
        README = gsub("[{]TREE[}]", tree, README)
        
        # Lister les fichiers à documenter
        # Paths = list.files(RDG_datadir, pattern=glob2rx(file_pattern),
                           # full.names=TRUE)
        Paths = list.files(RDG_datadir, full.names=TRUE)
        nPaths = length(Paths)
        if (nPaths == 0) {
            message(paste0("No files matching pattern found in ", RDG_datadir))
        }

        data_info = c()
        for (i in 1:nPaths) {
            path = Paths[i]

            RDG_FILE_DESCRIPTION = "**complete file description**"
            subsection = paste0("## File ", i)
            n_underscore = max(nchar_line - nchar(subsection) - 1, 0)
            subsection = paste0(subsection, " ",
                                paste0(rep("_", n_underscore), "",
                                       collapse=""))
            
            filename = paste0("Filename: ", basename(path))
            dir = paste0("Path: ", dirname(path))
            description = format_yml("Description",
                                     RDG_FILE_DESCRIPTION,
                                     0, nchar_line)

            if (!is.null(file_pattern) && grepl(utils::glob2rx(file_pattern), path)) {
                data = ASHE::read_tibble(path)
                column_info_list = paste0(
                    "- displayed_name: ", names(data), "\n",
                    "  long_name: <full \"human readable\" name>\n",
                    "  description:\n",
                    "  type: ", sapply(data, class), "\n",
                    "  unit: <if applicable>\n",
                    "  allowed_values: <list of possible values>"
                )
                column_info_list = paste0(column_info_list, collapse="\n\n")
                column_info = paste0("Column information:\n\n", column_info_list)
                missing = paste0("Missing data codes: ", "NA")
                add_info = paste0("Additional information:")
                content = paste(filename, dir, description, column_info,
                                missing, add_info, sep="\n\n")
            } else {
                add_info = paste0("Additional information:")
                content = paste(filename, dir, description, add_info, sep="\n\n")
            }
            
            file_info = paste0(subsection, "\n", content)
            data_info = c(data_info, file_info)
        }
        
        data_info = paste0(data_info, collapse="\n\n")        
        README = gsub("[{]DATA[}]", data_info, README)
        
        # Écrire le README
        writeLines(README, README_path)
        
        if (verbose) {
            message(paste0(round(idx / nDatasets * 100, 1),
                          "% : README for dataset ", convert_DOI_to_URL(dDOI),
                          " created at ", README_path))
        }
    }
    
    if (verbose && nDatasets > 1) {
        message(paste0("README generation complete: ", nDatasets, 
                      " README(s) created"))
    }
    
    invisible(NULL)
}


