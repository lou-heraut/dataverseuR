test_that("a short README field stays on one line", {
    expect_equal(cut_line("DOI", "https://doi.org/10.1/A"),
                 "DOI: https://doi.org/10.1/A")
})

test_that("a long README field is folded within the line width", {
    content = paste(rep("word", 40), collapse=" ")
    lines = strsplit(cut_line("Dataset title", content), "\n")[[1]]
    expect_equal(lines[1], "Dataset title: >")
    expect_true(all(startsWith(lines[-1], "  ")))
    expect_true(all(nchar(lines) <= 80))
    expect_equal(paste(trimws(lines[-1]), collapse=" "), content)
})

test_that("several values of a README field become a list", {
    lines = strsplit(format_yml("Contact email",
                                c("a@example.org", "b@example.org")),
                     "\n")[[1]]
    expect_equal(trimws(lines, "right"),
                 c("Contact email:", "  - a@example.org", "  - b@example.org"))
})

test_that("several README fields are written one per line", {
    expect_equal(format_yml(c("A", "B"), c("1", "2")), "A: 1\nB: 2")
    expect_error(format_yml(c("A", "B"), c("1", "2", "3")))
})
