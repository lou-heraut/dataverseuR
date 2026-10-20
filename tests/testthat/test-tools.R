test_that("a DOI becomes a directory name", {
    expect_equal(sanitize_doi("doi:10.57745/ABC123"), "doi_10-57745_ABC123")
    expect_equal(sanitize_doi(c("doi:10.1/A", "doi:10.2/B")),
                 c("doi_10-1_A", "doi_10-2_B"))
})

test_that("metadata paths are checked by extension", {
    expect_no_error(check_yml_format("metadata.yml"))
    expect_no_error(check_yml_format("metadata.yaml"))
    expect_error(check_yml_format("metadata.json"))
    expect_no_error(check_json_format("metadata.JSON"))
    expect_error(check_json_format("metadata.yml"))
})
