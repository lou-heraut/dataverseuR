# Helpers for the metadata conversion tests. The conversion functions write
# their output next to their input, so every case works in its own temporary
# directory.


# Writes a YAML text to metadata.yml in a new temporary directory.
write_yml = function(text) {
    dir = tempfile()
    dir.create(dir)
    path = file.path(dir, "metadata.yml")
    writeLines(text, path, useBytes=TRUE)
    return (path)
}


# Writes metadata fields to metadata.json in a new temporary directory, in the
# form get_datasets_metadata() saves them (a latestVersion object).
write_dl_json = function(..., block="citation") {
    dir = tempfile()
    dir.create(dir)
    path = file.path(dir, "metadata.json")
    metadata = list(latestVersion=list(metadataBlocks=list()))
    metadata$latestVersion$metadataBlocks[[block]] = list(fields=list(...))
    write(jsonlite::toJSON(metadata, auto_unbox=TRUE, pretty=TRUE), path)
    return (path)
}


# Field builders for write_dl_json().
primitive = function(typeName, value, multiple=FALSE) {
    list(typeName=typeName, multiple=multiple, typeClass="primitive",
         value=value)
}

compound = function(typeName, ...) {
    list(typeName=typeName, multiple=TRUE, typeClass="compound",
         value=list(...))
}

element = function(...) {
    values = list(...)
    mapply(primitive, names(values), values, SIMPLIFY=FALSE)
}


# The raw field of a JSON written by generate_metadata_json().
json_raw_field = function(json_path, typeName) {
    metadata = jsonlite::fromJSON(json_path, simplifyVector=FALSE)
    for (block in metadata$datasetVersion$metadataBlocks) {
        for (field in block$fields) {
            if (field$typeName == typeName) {
                return (field)
            }
        }
    }
    return (NULL)
}


# The values of that field: a character vector for a simple field, one named
# character vector per element for a compound field.
json_field = function(json_path, typeName) {
    value = json_raw_field(json_path, typeName)$value
    if (is.list(value) && length(value) > 0 && is.list(value[[1]])) {
        return (lapply(value, function(x) sapply(x, "[[", "value")))
    }
    return (unlist(value))
}


# Sorts the names of a nested list, so that two lists compare without regard
# to field order.
sort_names = function(x) {
    if (!is.list(x)) {
        return (x)
    }
    if (!is.null(names(x))) {
        x = x[order(names(x))]
    }
    return (lapply(x, sort_names))
}
