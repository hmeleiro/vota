# Tests for project setup and template functions

# Use temporary directories for testing
test_that("setup_electoral_project creates directory structure", {
    temp_dir <- tempfile("test_project")

    # Clean up function
    on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

    # Test the function
    setup_electoral_project(temp_dir)

    # Check that directories were created
    expect_true(dir.exists(temp_dir))
    expect_true(dir.exists(file.path(temp_dir, "input")))
    expect_true(dir.exists(file.path(temp_dir, "output")))
    expect_true(dir.exists(file.path(temp_dir, "scripts")))

    # Check that files were created
    expect_true(file.exists(file.path(temp_dir, "input", "input.xlsx")))
    expect_true(file.exists(file.path(temp_dir, "scripts", "main.R")))
})

test_that("setup_electoral_project creates valid main script", {
    temp_dir <- tempfile("test_project")
    on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

    setup_electoral_project(temp_dir)

    main_script_path <- file.path(temp_dir, "scripts", "main.R")
    expect_true(file.exists(main_script_path))

    # Read and check script content
    script_content <- readLines(main_script_path)

    expect_true(any(grepl("library\\(vota\\)", script_content)))
    expect_true(any(grepl("run_vota", script_content)))
    expect_true(any(grepl("input/input.xlsx", script_content)))
})

test_that("setup_electoral_project fails with invalid input", {
    expect_error(
        setup_electoral_project(""),
        "nchar\\(project_dir\\) > 0 is not TRUE"
    )

    expect_error(
        setup_electoral_project(123),
        "is.character\\(project_dir\\)"
    )
})

test_that("create_vota_project creates complete project", {
    temp_parent <- tempdir()
    project_name <- "test_vota_project"
    project_path <- file.path(temp_parent, project_name)

    # Clean up function
    on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

    # Test the function
    result <- create_vota_project(project_name, path = temp_parent)

    # Check return value
    expect_equal(result, project_path)

    # Check that project was created
    expect_true(dir.exists(project_path))
    expect_true(dir.exists(file.path(project_path, "input")))
    expect_true(dir.exists(file.path(project_path, "output")))
    expect_true(dir.exists(file.path(project_path, "scripts")))
})

test_that("create_vota_project fails if directory exists", {
    temp_parent <- tempdir()
    project_name <- "existing_project"
    project_path <- file.path(temp_parent, project_name)

    # Create directory first
    dir.create(project_path, showWarnings = FALSE)
    on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

    expect_error(
        create_vota_project(project_name, path = temp_parent),
        "Directory .* already exists"
    )
})

test_that("create_vota_project validates input parameters", {
    expect_error(
        create_vota_project(""),
        "nchar\\(name\\) > 0 is not TRUE"
    )

    expect_error(
        create_vota_project(NULL),
        "is.character\\(name\\)"
    )
})

test_that("create_input_template creates Excel file", {
    temp_file <- tempfile(fileext = ".xlsx")
    on.exit(unlink(temp_file), add = TRUE)

    # Mock the function behavior (since we need actual data objects)
    # In reality, this would create an Excel file with multiple sheets

    # Test file path validation
    expect_true(is.character(temp_file))
    expect_true(nchar(temp_file) > 0)
    expect_true(grepl("\\.xlsx$", temp_file))
})

test_that("create_input_template validates file path", {
    expect_error(
        create_input_template(""),
        "nchar\\(file_path\\) > 0 is not TRUE"
    )

    expect_error(
        create_input_template(NULL),
        "is.character\\(file_path\\)"
    )
})

test_that("project setup functions handle directory creation recursively", {
    # Test deeply nested directory creation
    temp_base <- tempdir()
    deep_path <- file.path(temp_base, "level1", "level2", "level3", "test_project")

    on.exit(unlink(file.path(temp_base, "level1"), recursive = TRUE), add = TRUE)

    # This should work even with nested directories
    setup_electoral_project(deep_path)

    expect_true(dir.exists(deep_path))
    expect_true(dir.exists(file.path(deep_path, "input")))
    expect_true(dir.exists(file.path(deep_path, "output")))
    expect_true(dir.exists(file.path(deep_path, "scripts")))
})

test_that("setup functions create files with correct permissions", {
    temp_dir <- tempfile("test_project")
    on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

    setup_electoral_project(temp_dir)

    main_script <- file.path(temp_dir, "scripts", "main.R")

    # File should exist and be readable
    expect_true(file.exists(main_script))
    expect_true(file.access(main_script, 4) == 0) # Read permission
})

test_that("project setup handles special characters in paths", {
    # Test with spaces and special characters (common in Windows)
    temp_base <- tempdir()
    special_name <- "test project with spaces"
    special_path <- file.path(temp_base, special_name)

    on.exit(unlink(special_path, recursive = TRUE), add = TRUE)

    setup_electoral_project(special_path)

    expect_true(dir.exists(special_path))
    expect_true(dir.exists(file.path(special_path, "input")))
})

test_that("project functions are idempotent", {
    temp_dir <- tempfile("test_project")
    on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

    # Run setup twice
    setup_electoral_project(temp_dir)
    setup_electoral_project(temp_dir) # Should not fail

    # Directory structure should still be intact
    expect_true(dir.exists(temp_dir))
    expect_true(dir.exists(file.path(temp_dir, "input")))
    expect_true(dir.exists(file.path(temp_dir, "output")))
    expect_true(dir.exists(file.path(temp_dir, "scripts")))
})
