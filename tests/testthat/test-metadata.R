# YAML -> JSON ________________________________________________________________

# Two authors, so that each case below has a repeated field name.
authors = c("author:",
            "- authorName: Dupont, Camille",
            "- authorName: Martin, Alex")

test_that("a field with one element keeps its sub-fields, unnumbered", {
    path = write_yml(c("title: t", authors,
                       "software:",
                       "- softwareName: Model",
                       "  softwareVersion: '2.1'"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "software"),
                 list(c(softwareName="Model", softwareVersion="2.1")))
})

test_that("each sub-field stays with its own element", {
    path = write_yml(c("title: t",
                       "keyword:",
                       "- keywordValue: a",
                       "- keywordValue: b",
                       "  keywordVocabulary: V2",
                       "- keywordValue: c",
                       "  keywordVocabulary: V3"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "keyword"),
                 list(c(keywordValue="a"),
                      c(keywordValue="b", keywordVocabulary="V2"),
                      c(keywordValue="c", keywordVocabulary="V3")))
})

test_that("a sub-field present in a single element is kept", {
    path = write_yml(c("title: t",
                       "timePeriodCovered:",
                       "- timePeriodCoveredStart: '1990-01-01'",
                       "  timePeriodCoveredEnd: '2000-12-31'",
                       "- timePeriodCoveredStart: '2010-01-01'"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "timePeriodCovered"),
                 list(c(timePeriodCoveredStart="1990-01-01",
                        timePeriodCoveredEnd="2000-12-31"),
                      c(timePeriodCoveredStart="2010-01-01")))
})

test_that("every value of a multi-valued simple field is kept", {
    path = write_yml(c("title: t", authors,
                       "language:",
                       "- French",
                       "- English"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "language"), c("French", "English"))
})

test_that("a single value of a multi-valued field is sent as a list", {
    path = write_yml(c("title: t", authors,
                       "subject: Earth and Environmental Sciences"))
    json = generate_metadata_json(path)
    field = json_raw_field(json, "subject")
    expect_type(field$value, "list")
    expect_equal(unlist(field$value), "Earth and Environmental Sciences")
})

test_that("a YAML without any repeated field name is converted", {
    path = write_yml(c("title: t",
                       "author:",
                       "- authorName: Dupont, Camille"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "title"), "t")
    expect_equal(json_field(json, "author"),
                 list(c(authorName="Dupont, Camille")))
})

test_that("values are kept as written, without YAML typing", {
    path = write_yml(c("title: t", authors,
                       "software:",
                       "- softwareName: Model",
                       "  softwareVersion: 1.10",
                       "kindOfDataOther: no"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "software"),
                 list(c(softwareName="Model", softwareVersion="1.10")))
    expect_equal(json_field(json, "kindOfDataOther"), "no")
})

test_that("a compound field with one element may skip the dash", {
    path = write_yml(c("title: t", authors,
                       "software:",
                       "  softwareName: Model",
                       "  softwareVersion: '2.1'"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "software"),
                 list(c(softwareName="Model", softwareVersion="2.1")))
})

test_that("a sub-field written alone makes the single element of its field", {
    path = write_yml(c("title: t", authors,
                       "country: France",
                       "otherGeographicCoverage: Rhone"))
    json = generate_metadata_json(path)
    expect_equal(json_field(json, "geographicCoverage"),
                 list(c(country="France", otherGeographicCoverage="Rhone")))
})

test_that("writing mistakes stop with a message that says what to fix", {
    expect_error(generate_metadata_json(write_yml(c("title: t", "autor:",
                                                    "- authorName: Dupont"))),
                 "Unknown metadata field.*autor")
    expect_error(generate_metadata_json(write_yml(c("title: t", authors,
                                                    "keyword:",
                                                    "- keywordValue: a",
                                                    "  keywordVocab: V"))),
                 "Unknown sub-field of keyword: keywordVocab")
    expect_error(generate_metadata_json(write_yml(c("title: t", authors,
                                                    "authorAffiliation: Lab"))),
                 "authorAffiliation should be written inside author")
    expect_error(generate_metadata_json(write_yml(c("title: t",
                                                    "author: Dupont"))),
                 "author is made of sub-fields")
    expect_error(generate_metadata_json(write_yml(c("title:", "- a", "- b"))),
                 "title takes a single value")
})

test_that("the JSON file is written next to the YAML file", {
    dir = file.path(tempfile(), "x_yml")
    dir.create(dir, recursive=TRUE)
    path = file.path(dir, "metadata.yml")
    writeLines(c("title: t", authors), path)
    expect_equal(generate_metadata_json(path),
                 file.path(dir, "metadata.json"))
})


# JSON -> YAML ________________________________________________________________

test_that("each sub-field stays with its own element, back to YAML", {
    path = write_dl_json(
        primitive("title", "t"),
        compound("keyword",
                 element(keywordValue="a"),
                 element(keywordValue="b", keywordVocabulary="V2"),
                 element(keywordValue="c", keywordVocabulary="V3")))
    yml = read_yml(convert_metadata_to_yml(path))
    expect_equal(yml$keyword,
                 list(list(keywordValue="a"),
                      list(keywordValue="b", keywordVocabulary="V2"),
                      list(keywordValue="c", keywordVocabulary="V3")))
})

test_that("a sub-field present in a single element is kept, back to YAML", {
    path = write_dl_json(
        primitive("title", "t"),
        compound("timePeriodCovered",
                 element(timePeriodCoveredStart="1990-01-01",
                         timePeriodCoveredEnd="2000-12-31"),
                 element(timePeriodCoveredStart="2010-01-01")))
    yml = read_yml(convert_metadata_to_yml(path))
    expect_equal(yml$timePeriodCovered,
                 list(list(timePeriodCoveredStart="1990-01-01",
                           timePeriodCoveredEnd="2000-12-31"),
                      list(timePeriodCoveredStart="2010-01-01")))
})

test_that("every value of a multi-valued simple field is kept, back to YAML", {
    path = write_dl_json(
        primitive("title", "t"),
        primitive("language", c("French", "English"), multiple=TRUE))
    yml = read_yml(convert_metadata_to_yml(path))
    expect_equal(yml$language, c("French", "English"))
})

test_that("a single value of a multi-valued field is written as a scalar", {
    path = write_dl_json(
        primitive("title", "t"),
        primitive("subject", "Earth and Environmental Sciences",
                  multiple=TRUE))
    yml_path = convert_metadata_to_yml(path)
    expect_true("subject: Earth and Environmental Sciences" %in%
                readLines(yml_path))
})


test_that("a JSON written by generate_metadata_json() converts back", {
    json = generate_metadata_json(write_yml(c("title: t", authors)))
    yml = read_yml(convert_metadata_to_yml(json, overwrite=TRUE))
    expect_equal(yml$title, "t")
    expect_equal(yml$author,
                 list(list(authorName="Dupont, Camille"),
                      list(authorName="Martin, Alex")))
})


# Round trip __________________________________________________________________

test_that("the values of a full YAML survive a round trip", {
    yml_path = write_yml(readLines(test_path("fixtures", "metadata.yml"),
                                   encoding="UTF-8"))
    json_path = generate_metadata_json(yml_path)

    # The JSON sent to Dataverse is a datasetVersion object, the one read back
    # a latestVersion object, read and saved as get_datasets_metadata() does.
    metadata = jsonlite::fromJSON(json_path, simplifyDataFrame=FALSE,
                                  simplifyVector=TRUE)
    names(metadata)[names(metadata) == "datasetVersion"] = "latestVersion"
    dl_dir = tempfile()
    dir.create(dl_dir)
    dl_path = file.path(dl_dir, "metadata.json")
    write(jsonlite::toJSON(metadata, auto_unbox=TRUE, pretty=TRUE), dl_path)

    back_path = convert_metadata_to_yml(dl_path)
    expect_equal(sort_names(read_yml(back_path)),
                 sort_names(read_yml(yml_path)))
})
