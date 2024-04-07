import argparse
import json
from jsonschema import validate
import sys

schema_files = [
    "schemas/attestation.json",
    "schemas/rws_non-primary.json",
    "schemas/rws_primary.json",
]


if __name__ == "__main__":
    # Create Argument Parser
    parser = argparse.ArgumentParser(
        prog="python3 validate_json.py",
        description="Validate input json against the different schemas for RWS and Attestation",
    )
    parser.add_argument("json_input")

    args = parser.parse_args()

    try:
        with open(args.json_input, "r") as f:
            input_json = json.load(f)
    except:
        sys.exit(1)  # in case input file is empty, does not exist, etc.

    is_not_valid = 0
    for file in schema_files:
        with open(file, "r") as f:
            schema = json.load(f)
        try:
            validate(input_json, schema=schema)
        except:
            is_not_valid += 1

    if is_not_valid == len(schema_files):
        sys.exit(1)
    else:
        sys.exit(0)
