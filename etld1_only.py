import argparse
from publicsuffixlist import PublicSuffixList


if __name__ == "__main__":
    # Create Argument Parser
    parser = argparse.ArgumentParser(
        prog="python3 keep_etld1.py",
        description="Output the https:// scheme and etld+1 only of the domain given in input",
    )
    parser.add_argument(
        "-i",
        "--inputs",
        nargs="+",
        help="Domains for which only etld+1 should be kept",
        required=True,
    )

    args = parser.parse_args()
    psl = PublicSuffixList()
    for domain in args.inputs:
        # split on scheme delimiter and keep last item of returned array, works
        # even though scheme not specified, and output https (expected for
        # Privacy Sandbox APIs calls)
        print("https://{}\n".format(psl.privatesuffix(domain.split("://")[-1])), end="")
