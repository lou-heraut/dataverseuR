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

test_that("a directory summary counts its directories and files", {
    dir = tempfile()
    dir.create(file.path(dir, "sub"), recursive=TRUE)
    writeLines("x", file.path(dir, "a.txt"))
    writeLines("x", file.path(dir, "sub", "b.txt"))
    expect_equal(get_info_dir(dir), "1 directory, 2 files")
    dir.create(file.path(dir, "other"))
    expect_equal(get_info_dir(dir), "2 directories, 2 files")
})

test_that("tables are converted into the output directory, keeping subdirectories", {
    # ASHE::convert_tibble() calls lubridate, which ASHE does not declare.
    skip_if_not_installed("lubridate")
    input_dir = tempfile()
    output_dir = tempfile()
    dir.create(file.path(input_dir, "sub"), recursive=TRUE)
    writeLines(c("a;b", "1;2"), file.path(input_dir, "table.csv"))
    writeLines(c("a\tb", "1\t2"), file.path(input_dir, "sub", "other.tab"))
    writeLines("Notes", file.path(input_dir, "README.txt"))
    clean_datasets_files(input_dir, output_dir, verbose=FALSE)
    expect_setequal(list.files(output_dir, recursive=TRUE),
                    c("table.csv", file.path("sub", "other.csv")))
})

test_that("cleaning needs one output directory per input directory", {
    expect_error(clean_datasets_files(c("a", "b"), "c"),
                 "one directory per input directory")
})
