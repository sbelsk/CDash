<?php

declare(strict_types=1);

namespace App\Utils;

use DOMDocument;
use App\Exceptions\CDashXMLValidationException;

class SubmissionUtils
{
    /**
     * Figure out what type of XML file this is
     * @return array<string,mixed>
     * @throws CDashXMLValidationException
     */
    public static function get_xml_type(mixed $filehandle, string $xml_file): array
    {
        $file = '';
        $handler = null;
        $schemas_dir = base_path()."/app/Validators/Schemas";
        $schema_file = null;
        // read file contents until we recognize its elements
        while ($file === '' && !feof($filehandle)) {
            $content = fread($filehandle, 8192);
            if ($content === false) {
                // if read failed, fallback onto default null values
                break;
            }
            if (str_contains($content, '<Update')) {
                // Should be first otherwise confused with Build
                $handler = \UpdateHandler::class;
                $file = 'Update';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<Build')) {
                $handler = \BuildHandler::class;
                $file = 'Build';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<Configure')) {
                $handler = \ConfigureHandler::class;
                $file = 'Configure';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<Testing')) {
                $handler = \TestingHandler::class;
                $file = 'Test';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<CoverageLog')) {
                // Should be before coverage
                $handler = \CoverageLogHandler::class;
                $file = 'CoverageLog';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<Coverage')) {
                $handler = \CoverageHandler::class;
                $file = 'Coverage';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<report')) {
                $handler = \CoverageJUnitHandler::class;
                $file = 'CoverageJUnit';
            } elseif (str_contains($content, '<Notes')) {
                $handler = \NoteHandler::class;
                $file = 'Notes';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<DynamicAnalysis')) {
                $handler = \DynamicAnalysisHandler::class;
                $file = 'DynamicAnalysis';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<Project')) {
                $handler = \ProjectHandler::class;
                $file = 'Project';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<Upload')) {
                $handler = \UploadHandler::class;
                $file = 'Upload';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            } elseif (str_contains($content, '<testsuite')) {
                $handler = \TestingJUnitHandler::class;
                $file = 'TestJUnit';
            } elseif (str_contains($content, '<Done')) {
                $handler = \DoneHandler::class;
                $file = 'Done';
                $schema_file = "{$schemas_dir}/{$file}.xsd";
            }
        }

        // restore the file descriptor to beginning of file
        rewind($filehandle);

        // perform minimal error checking as a sanity check
        if ($file === '') {
            throw new CDashXMLValidationException(["ERROR: Could not determine submission"
                                                  ." file type for: '{$xml_file}'"]);
        }
        if (isset($schema_file) && !file_exists($schema_file)) {
            throw new CDashXMLValidationException(["ERROR: Could not find schema file '{$schema_file}'"
                                                  ." to validate input file: '{$xml_file}'"]);
        }

        return [
            'file_handle' => $filehandle,
            'xml_handler' => $handler,
            'xml_type' => $file,
            'xml_schema' => $schema_file,
        ];
    }


    /**
     * Validate the given XML file based on its type
     * @throws CDashXMLValidationException
     */
    public static function validate_xml(string $xml_file, string $schema_file): void
    {
        $errors = [];

        // let us control the failures so we can continue
        // parsing files instead of crashing midway
        libxml_use_internal_errors(true);

        // load the input file to be validated
        $xml = new DOMDocument();
        $xml->load($xml_file, LIBXML_PARSEHUGE);

        // run the validator and collect errors if there are any
        if (!$xml->schemaValidate($schema_file)) {
            $validation_errors = libxml_get_errors();
            foreach ($validation_errors as $error) {
                if ($error->level == LIBXML_ERR_ERROR || $error->level == LIBXML_ERR_FATAL) {
                    $errors[] = "ERROR: {$error->message} in {$error->file},"
                                ." line: {$error->line}, column: {$error->column}";
                }
            }
            libxml_clear_errors();
        }

        if (count($errors) !== 0) {
            throw new CDashXMLValidationException($errors);
        }
    }
}
