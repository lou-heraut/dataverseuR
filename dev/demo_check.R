# End-to-end check of the metadata conversion on the demo instance of
# Recherche Data Gouv. Creates a draft dataset from the test YAML, reads its
# metadata back and compares them with what was sent, modifies it and
# compares again, then deletes the draft. Run from the root of the package,
# with a .env-demo file: Rscript dev/demo_check.R [collection]


devtools::load_all(".", quiet=TRUE)
dotenv::load_dot_env(file=".env-demo")
if (sub("/+$", "", Sys.getenv("BASE_URL")) !=
    "https://demo.recherche.data.gouv.fr") {
    stop("BASE_URL is not the demo instance.")
}

args = commandArgs(TRUE)
collection = if (length(args) > 0) args[1] else "espacegenerique"
work_dir = tempfile()
dir.create(work_dir)


# The values of a dataset version, one text per field, element and sub-field.
flatten_values = function (version) {
    values = c()
    for (block in version$metadataBlocks) {
        for (field in block$fields) {
            if (field$typeClass == "compound") {
                elements = if (field$multiple) field$value else list(field$value)
                for (i in seq_along(elements)) {
                    for (sub in elements[[i]]) {
                        values = c(values, paste(field$typeName, i,
                                                 sub$typeName, sub$value,
                                                 sep=" | "))
                    }
                }
            } else {
                values = c(values, paste(field$typeName, "-", "-",
                                         unlist(field$value), sep=" | "))
            }
        }
    }
    return (sort(values))
}

# Sends a YAML file to the dataset, reads it back and reports the differences.
check = function (label, yml_path, dataset_DOI=NULL) {
    json_path = generate_metadata_json(yml_path, overwrite=TRUE)
    if (is.null(dataset_DOI)) {
        dataset_DOI = create_datasets(collection, json_path, verbose=FALSE)
    } else {
        modify_datasets(collection, dataset_DOI, json_path,
                        wait_time=1, verbose=FALSE)
    }
    back_path = file.path(dirname(yml_path), "back.json")
    get_datasets_metadata(dataset_DOI, back_path, overwrite=TRUE,
                          verbose=FALSE)
    sent = flatten_values(jsonlite::fromJSON(json_path,
                                             simplifyVector=FALSE)$datasetVersion)
    back = flatten_values(jsonlite::fromJSON(back_path,
                                             simplifyVector=FALSE)$latestVersion)
    message(label, ": ", length(sent), " values sent, ", length(back),
            " read back, identical: ", identical(sent, back))
    for (x in setdiff(sent, back)) message("  sent only: ", x)
    for (x in setdiff(back, sent)) message("  read only: ", x)
    return (dataset_DOI)
}


yml_path = file.path(work_dir, "create", "metadata.yml")
dir.create(dirname(yml_path))
invisible(file.copy(file.path("tests", "testthat", "fixtures", "metadata.yml"),
                     yml_path))
dataset_DOI = check("Creation", yml_path)
message("Draft dataset: ", dataset_DOI)

tryCatch({
    # New title, one language less, one field more.
    lines = readLines(yml_path, encoding="UTF-8")
    lines = sub("^title: .*", "title: Title modified by the check", lines)
    lines = lines[lines != "- English"]
    lines = c(lines, "", "otherReferences:", "- Invented reference")
    yml_path = file.path(work_dir, "modify", "metadata.yml")
    dir.create(dirname(yml_path))
    writeLines(lines, yml_path, useBytes=TRUE)
    invisible(check("Modification", yml_path, dataset_DOI))
}, finally={
    delete_datasets(dataset_DOI, verbose=FALSE)
    message("Draft dataset deleted.")
})
