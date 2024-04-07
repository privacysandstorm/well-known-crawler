import argparse
import json
from jsonschema import validate
import sys

if __name__ == "__main__":
    # Create Argument Parser
    parser = argparse.ArgumentParser(
        prog="python3 primary_rws.py",
        description="Validate if input json is RWS primary",
    )
    parser.add_argument("json_input")

    args = parser.parse_args()

    try:
        with open(args.json_input, "r") as f:
            input_json = json.load(f)
    except:
        sys.exit(1)  # in case input file is empty, does not exist, etc.

    with open("schemas/rws_primary.json", "r") as f:
        schema = json.load(f)
    try:
        validate(input_json, schema=schema)
    except:
        sys.exit(1)
    sys.exit(0)
