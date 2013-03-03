#!/bin/sh
APP_NAME=https-everywhere

# builds a .xpi from the git repository, placing the .xpi in the root
# of the repository.
#
# invoke with no arguments to build from the current src directory.
#
#  ./makexpi.sh
#
# OR, invoke with a tag name to build a specific branch or tag.
#
# e.g.:
#
#  ./makexpi.sh 0.2.3.development.2

cd "`dirname $0`"

[ -d pkg ] || mkdir pkg

# If the command line argument is a tag name, check that out and build it
if [ -n "$1" ] && [ "$2" != "--no-recurse" ] ; then
	BRANCH=`git branch | head -n 1 | cut -d \  -f 2-`
	SUBDIR=checkout
	[ -d $SUBDIR ] || mkdir $SUBDIR
	cp -r -f -a .git $SUBDIR
	cd $SUBDIR
	git reset --hard "$1"
  # Use the version of the build script that was current when that
  # tag/release/branch was made.
  ./makexpi.sh $1 --no-recurse || exit 1
  # The fact that the above works even when the thing you are building predates
  # support for --no-recurse in this script is (1) non-intuitive; (2) crazy; and (3)
  # involves two pristine checkouts of $1 within each other

  # Now escape from the horrible mess we've made
  cd ..
	XPI_NAME="$APP_NAME-$1.xpi"
  # In this mad recursive situation, sometimes old buggy build scripts make
  # the xpi as ./pkg :(
  if ! cp $SUBDIR/pkg/$XPI_NAME pkg/ ; then
    echo Recovering from hair-raising recursion:
    echo cp $SUBDIR/pkg pkg/$XPI_NAME
    cp $SUBDIR/pkg pkg/$XPI_NAME
  fi
  rm -rf $SUBDIR
  exit 0
fi

if [ -f utils/trivial-validate.py ]; then
	VALIDATE="python utils/trivial-validate.py --ignoredups google --ignoredups facebook"
elif [ -f trivial-validate.py ] ; then
	VALIDATE="python trivial-validate.py --ignoredups google --ignoredups facebook"
elif [ -x utils/trivial-validate ] ; then
  # This case probably never happens
	VALIDATE=./utils/trivial-validate
else
	VALIDATE=./trivial-validate
fi

if $VALIDATE src/chrome/content/rules >&2
then
  echo Validation of included rulesets completed. >&2
  echo >&2
else
  echo ERROR: Validation of rulesets failed. >&2
  exit 1
fi

if [ -f utils/relaxng.xml -a -x "$(which xmllint)" ] >&2
then
<<<<<<< HEAD
  if xmllint --noout --relaxng relaxng.xml src/chrome/content/rules/*.xml
=======
  if xmllint --noout --relaxng utils/relaxng.xml src/chrome/content/rules/*.xml
>>>>>>> FETCH_HEAD
  then
    echo Validation of rulesets with RELAX NG grammar completed. >&2
  else
    echo ERROR: Validation of rulesets with RELAX NG grammar failed. >&2
    exit 1
  fi
else
  echo Validation of rulesets with RELAX NG grammar was SKIPPED. >&2
fi

if [ -x ./utils/compare-locales.sh ] >&2
then
  if ./utils/compare-locales.sh >&2
  then
    echo Validation of included locales completed. >&2
  else
    echo ERROR: Validation of locales failed. >&2
    exit 1
  fi
fi

# The name/version of the XPI we're building comes from src/install.rdf
XPI_NAME="pkg/$APP_NAME-`grep em:version src/install.rdf | sed -e 's/[<>]/	/g' | cut -f3`"
if [ "$1" ]; then
	XPI_NAME="$XPI_NAME.xpi"
else
	XPI_NAME="$XPI_NAME~pre.xpi"
fi

[ -d pkg ] || mkdir pkg

# Used for figuring out which branch to pull from when viewing source for rules
GIT_OBJECT_FILE=".git/refs/heads/master"
<<<<<<< HEAD
GIT_COMMIT_ID="HEAD"
if [ -e "$GIT_OBJECT_FILE" ]; then
	GIT_COMMIT_ID=$(cat "$GIT_OBJECT_FILE")
fi

# Merge all the .xml rulesets into a single "default.rulesets" file -- this
# prevents inodes from wasting disk space, but more importantly, works around
# the fact that zip does not perform well on a pile of small files.
cd src
RULESETS=chrome/content/rules/default.rulesets
echo "Creating ruleset library..."
echo "<rulesetlibrary gitcommitid=\"${GIT_COMMIT_ID}\">" > $RULESETS
# Include the filename.xml as the "f" attribute
for file in chrome/content/rules/*.xml; do
	xmlInsertString="<ruleset" 
	fileName=$(basename "$file")
	fileContent=$(sed "s/${xmlInsertString}/${xmlInsertString} f=\"${fileName}\"/" "chrome/content/rules/${fileName}")
	echo "$fileContent" >> $RULESETS
done
echo "</rulesetlibrary>" >> $RULESETS

echo "Removing whitespaces and comments..."
rulesize() {
	echo `wc -c $RULESETS | cut -d \  -f 1`
}
CRUSH=`rulesize`
sed -i -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba' $RULESETS
sed -i ':a;N;$!ba;s/\n//g;s/>[ 	]*</></g;s/[ 	]*to=/ to=/g;s/[ 	]*from=/ from=/g;s/ \/>/\/>/g' $RULESETS
echo "Crushed $CRUSH bytes of rulesets into `rulesize`"
=======
export GIT_COMMIT_ID="HEAD"
if [ -e "$GIT_OBJECT_FILE" ]; then
	export GIT_COMMIT_ID=$(cat "$GIT_OBJECT_FILE")
fi
>>>>>>> FETCH_HEAD

python ./utils/merge-rulesets.py
cd src

# Build the XPI!
rm -f "../$XPI_NAME"
zip -q -X -9r "../$XPI_NAME" . "-x@../.build_exclusions"

ret="$?"
if [ "$ret" != 0 ]; then
    rm -f "../$XPI_NAME"
    exit "$?"
else
  echo >&2 "Total included rules: `find chrome/content/rules -name "*.xml" | wc -l`"
  echo >&2 "Rules disabled by default: `find chrome/content/rules -name "*.xml" | xargs grep -F default_off | wc -l`"
  echo >&2 "Created $XPI_NAME"
  if [ -n "$BRANCH" ]; then
    cd ../..
    cp $SUBDIR/$XPI_NAME pkg
    rm -rf $SUBDIR
  fi
fi
