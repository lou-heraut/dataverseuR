


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
                       include.dirs=TRUE,
                       all.files=FALSE,
                       full.names=TRUE)
    n_files = sum(file.info(paths)$isdir == FALSE, na.rm=TRUE)
    n_dirs = sum(file.info(paths)$isdir == TRUE, na.rm=TRUE)
    
    info = sprintf(
        "%d %s, %d file%s",
        n_dirs,
        ifelse(n_dirs == 1, "directory", "directories"),
        n_files,
        ifelse(n_files == 1, "", "s"))
    
    return (info)
}



#' @title clean_datasets_files
#' @description Convert the tabular files of a directory to clean CSV files with ASHE::convert_tibble, keeping its subdirectories. By default, processes common tabular formats while excluding README and license files.
#' @param input_dir A vector of character strings: the directories whose files are converted, for example those filled by [download_datasets_files()].
#' @param output_dir A vector of character strings, one per input directory: where the converted files are saved.
#' @param include_extensions A vector of character strings representing file extensions to include for cleaning. Defaults to `c("csv", "txt", "tab")`. Extensions should be provided without the dot.
#' @param exclude_patterns A vector of character strings representing patterns to exclude from cleaning. Files whose name matches any of these patterns (case-insensitive) will be skipped. Defaults to `c("tmp", "readme", "license", "licence", "citation")`. Set to `NULL` to disable exclusion.
#' @param output_extension A character string representing the output file extension. Defaults to `".csv"`. The original extension will be replaced by this one.
#' @param overwrite A logical value indicating whether to overwrite existing files. Defaults to FALSE.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return A list of results from ASHE::convert_tibble for each processed file, by input directory.
#' @examples
#' \dontrun{
#' # Convert the files of a downloaded dataset
#' clean_datasets_files("LNBEGZ/original", "LNBEGZ/cleaned")
#' 
#' # Only CSV files, without any exclusion
#' clean_datasets_files("LNBEGZ/original", "LNBEGZ/cleaned",
#'                      include_extensions="csv", exclude_patterns=NULL)
#' }
#' @seealso
#' - [download_datasets_files()] for downloading dataset files
#' - [ASHE::convert_tibble()] for the underlying conversion function
#' - [dataverseuR GitHub documentation](https://github.com/lou-heraut/dataverseuR) <https://github.com/lou-heraut/dataverseuR>
#' @md
#' @export
clean_datasets_files = function(input_dir,
                                output_dir,
                                include_extensions=c("csv", "txt", "tab"),
                                exclude_patterns=c("tmp", "readme", "license",
                                                   "licence", "citation"),
                                output_extension=".csv",
                                overwrite=FALSE,
                                verbose=TRUE) {

    if (length(output_dir) != length(input_dir)) {
        stop("output_dir needs one directory per input directory.")
    }
    all_results = list()

    for (i in seq_along(input_dir)) {
        if (!dir.exists(input_dir[i])) {
            warning(paste0("Input directory does not exist: ", input_dir[i]))
            next
        }

        # Paths relative to the input directory, to keep its subdirectories.
        files = list.files(input_dir[i], recursive=TRUE)
        files = files[tolower(tools::file_ext(files)) %in%
                      tolower(include_extensions)]

        if (!is.null(exclude_patterns) && length(exclude_patterns) > 0) {
            excluded = rep(FALSE, length(files))
            for (pattern in exclude_patterns) {
                excluded = excluded |
                    grepl(tolower(pattern), tolower(basename(files)))
            }
            if (verbose && any(excluded)) {
                message(paste0("Excluded ", sum(excluded),
                               " file(s) matching exclusion patterns: ",
                               paste(basename(files[excluded]), collapse=", ")))
            }
            files = files[!excluded]
        }

        if (length(files) == 0) {
            if (verbose) {
                message(paste0("No file to convert in ", input_dir[i]))
            }
            next
        }

        input_paths = file.path(input_dir[i], files)
        output_paths = file.path(output_dir[i], files)
        if (!is.null(output_extension) && output_extension != "") {
            output_paths = sub("\\.[^.]*$", output_extension, output_paths)
        }
        for (dir in unique(dirname(output_paths))) {
            dir.create(dir, recursive=TRUE, showWarnings=FALSE)
        }

        if (verbose) {
            message(paste0("Processing ", length(files), " file(s) from ",
                           input_dir[i]))
        }
        all_results[[input_dir[i]]] = mapply(ASHE::convert_tibble,
                                             path=input_paths,
                                             output_path=output_paths,
                                             read_guess_sep=TRUE,
                                             read_guess_text_encoding=TRUE,
                                             overwrite=overwrite,
                                             SIMPLIFY=FALSE)
        if (verbose) {
            message(paste0(length(files), " file(s) saved in ", output_dir[i]))
        }
    }

    if (verbose && length(all_results) > 0) {
        message(paste0("Cleaning complete: ", sum(lengths(all_results)),
                       " file(s) processed"))
    }
    invisible(all_results)
}



#' @title create_datasets_README
#' @description Automatically generates README files for one or multiple datasets. Creates structured documentation including metadata, file descriptions, and column information for cleaned datasets.
#' @param dataset_DOI A vector of character strings of dataset DOI(s). A README will be created for each dataset.
#' @param dirpath A vector of character strings, one per dataset: the directory whose files the README describes, for example the one filled by [clean_datasets_files()].
#' @param README_path A vector of character strings, one per dataset: where the README is written. Defaults to `README.txt` in `dirpath`.
#' @param file_pattern A character string representing the file pattern to document in the README. Defaults to `"*.csv"`. Use standard glob patterns (e.g., `"*.tsv"`, `"*"` for all files).
#' @param overwrite A logical value indicating whether to overwrite existing README files. Defaults to `FALSE`.
#' @param BASE_URL A character string for the base URL of the Dataverse API. By default, it uses the value from the environment variable `BASE_URL`.
#' @param API_TOKEN A character string for the API token required to authenticate the request. By default, it uses the value from the environment variable `API_TOKEN`.
#' @param verbose If `FALSE`, no processing informations are displayed. Defaults to `TRUE`.
#' @return Invisible NULL. The README files are written to `README_path`.
#' @examples
#' \dontrun{
#' dotenv::load_dot_env()
#' 
#' # Describe the cleaned files of a dataset
#' dataset_DOI = "doi:10.57745/LNBEGZ"
#' create_datasets_README(dataset_DOI, "LNBEGZ/cleaned")
#' # README written in: LNBEGZ/cleaned/README.txt
#' 
#' # Elsewhere, describing the columns of TSV files, replacing an existing README
#' create_datasets_README(dataset_DOI, "LNBEGZ/cleaned",
#'                        README_path="LNBEGZ/README.txt",
#'                        file_pattern="*.tsv", overwrite=TRUE)
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
                                  dirpath,
                                  README_path=file.path(dirpath, "README.txt"),
                                  file_pattern="*.csv",
                                  overwrite=FALSE,
                                  BASE_URL=Sys.getenv("BASE_URL"),
                                  API_TOKEN=Sys.getenv("API_TOKEN"),
                                  verbose=TRUE) {

    nDatasets = length(dataset_DOI)
    if (length(dirpath) != nDatasets || length(README_path) != nDatasets) {
        stop("dirpath and README_path need one value per dataset.")
    }
    
    for (idx in 1:nDatasets) {
        dDOI = dataset_DOI[idx]
        RDG_datadir = dirpath[idx]
        readme_path = README_path[idx]
        
        if (!dir.exists(RDG_datadir)) {
            warning(paste0("Directory does not exist: ", RDG_datadir, 
                          ". Skipping dataset ", dDOI))
            next
        }
        
        if (file.exists(readme_path) && !overwrite) {
            warning(paste0("README already exists at ", readme_path, 
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
        
        # The files to describe, relative to dirpath, without the README.
        Paths = list.files(RDG_datadir, recursive=TRUE)
        Paths = Paths[normalizePath(file.path(RDG_datadir, Paths)) !=
                      normalizePath(readme_path, mustWork=FALSE)]
        nPaths = length(Paths)
        if (nPaths == 0) {
            message(paste0("No file to describe in ", RDG_datadir))
        }

        data_info = c()
        for (i in seq_len(nPaths)) {
            path = file.path(RDG_datadir, Paths[i])

            RDG_FILE_DESCRIPTION = "**complete file description**"
            subsection = paste0("## File ", i)
            n_underscore = max(nchar_line - nchar(subsection) - 1, 0)
            subsection = paste0(subsection, " ",
                                paste0(rep("_", n_underscore), "",
                                       collapse=""))
            
            filename = paste0("Filename: ", basename(path))
            # The directory of the file within the dataset, as in the tree.
            dir_in_dataset = dirname(Paths[i])
            if (dir_in_dataset != ".") {
                dir_in_dataset = file.path(".", dir_in_dataset)
            }
            dir = paste0("Path: ", dir_in_dataset)
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
        
        dir.create(dirname(readme_path), recursive=TRUE, showWarnings=FALSE)
        writeLines(README, readme_path)
        
        if (verbose) {
            message(paste0(round(idx / nDatasets * 100, 1),
                          "% : README for dataset ", convert_DOI_to_URL(dDOI),
                          " created at ", readme_path))
        }
    }
    
    if (verbose && nDatasets > 1) {
        message(paste0("README generation complete: ", nDatasets, 
                      " README(s) created"))
    }
    
    invisible(NULL)
}


