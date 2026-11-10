from portage.dep import use_reduce

deps = """
sys-libs/zlib
ssl? ( dev-libs/openssl )
!ssl? ( app-arch/xz-utils )
"""

for flags in ({"ssl"}, set()):
    result = use_reduce(deps, uselist=flags, eapi="8", flat=True)
    print("USE:", flags)
    print("Dependencies:", result)
