# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit toolchain-funcs

DESCRIPTION="Reminiscence to the screensaver that shipped until WinXP..."
HOMEPAGE="https://github.com/luebking/starfield"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/luebking/${PN}.git"
	SRC_URI=""
	KEYWORDS=""
else
	# Yes Lübking we are waiting for RC1!!
	SRC_URI="https://github.com/luebking/${PN}/releases/download/${PV}/${P}.tar.gz"
	KEYWORDS="-* ~amd64 ~x86 ~x86-fbsd"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE=""

DEPEND="media-libs/freeglut
		media-libs/libsdl
		media-libs/sdl-image
		virtual/glu
		virtual/opengl"
RDEPEND="${DEPEND}"

src_configure() {
	DATA_DIR="${EPREFIX}/usr/share/${PN}"
	sed -i	-e 's|sprintf(filename, "star_%d.jpg", i);|sprintf(filename, "'"${DATA_DIR}"'/star_%d.jpg", i);|g' \
			-e 's|char filename\[11\];|char filename[512];|g'  starfield.c \
			|| die "sed: unable to process file \"starfield.c\""
}

src_compile() {
	( $(tc-getCC) -o starfield starfield.c -O2 -lglut -lGL -lGLU -lSDL -lSDL_image || false ) \
		|| die "gcc: unable to compile ${PN}"
}

src_install() {
	dobin starfield
	insinto "${DATA_DIR}"
	doins star*.jpg
}
