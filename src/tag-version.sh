#! bin/bash

#tag-version.sh
#by Julian Sangillo
#Use: tag-version {prod-branch} {test-branch} {dev-branch}
#Output: {new-revision}
#Provides automated versioning of your commits using git tags each time your CI/CD workflow runs.
#Error Codes:
#- 32: A 'latest' tag exists without a corresponding annotated tag marking the last known version on the same commit.
#- 64: A 'latest' tag doesn't exist when pulling commits into test or production.
#- 128: Tag version is being attempted on neither the production, test, or dev branches. Branch is unknown.

PROD_BRANCH="$1";
TEST_BRANCH="$2";
DEV_BRANCH="$3";

outLog() {
	echo "$1"
} >&2

getLatestRevision() {
	outLog "Getting latest tagged revision ...";
	if [ "$(git tag -l *latest* | wc -l)" -eq "0" ]; then
                local INITIAL_COMMIT="$(git rev-list --full-history HEAD | tail -n 1)";

		outLog ":latest doesn't exist. Setting :latest to initial commit.";
		outLog "Initial Commit: $INITIAL_COMMIT";

                git tag latest $INITIAL_COMMIT;

		echo "NA";
		return 0
        fi

	echo "$(git tag --contains latest | grep v | tr -d 'v')"
}

getRevisionType() {
	local MESSAGE="$(git show -s --format=%s HEAD)";

	outLog "Getting revision type from commit message ...";
	outLog "(major, minor, build)";
	outLog "Message: $MESSAGE";

	if [[ "$MESSAGE" == *"#major"* ]]; then
		echo "major"
	elif [[ "$MESSAGE" == *"#minor"* ]]; then
		echo "minor"
	else
		echo "build"
	fi
}

split() { IFS="$1" read -r -a return_arr <<< "$2"; }

join() { local IFS="$1"; shift; echo "$*"; }

getNewRevision() {
	local REVISION_TYPE="$1";
	local OLD_VERSION="$2";

	outLog "Getting new revision from revision type and the old version ...";
	outLog "Revision Type: $REVISION_TYPE";

	if [ "$OLD_VERSION" = "NA" ]; then
		outLog "Old version doesn't exist. Using initial version.";
		echo "1.0.0.${DEV_BRANCH^^}";
		return 0
	fi

	outLog "Old Version: $OLD_VERSION";

	split '.' $OLD_VERSION;

	major_revision=${return_arr[0]};
	minor_revision=${return_arr[1]};
	build_number=${return_arr[2]};
	prerelease_tag="${DEV_BRANCH^^}";

	case $REVISION_TYPE in
		major)
			((major_revision++));
			minor_revision=0;
			build_number=0
			;;
		minor)
			((minor_revision++));
			build_number=0
			;;
		build)
			((build_number++))
			;;
		esac

	echo "$(join . $major_revision $minor_revision $build_number $prerelease_tag)"
}

pullRevisionIntoTest() {
	local OLD_VERSION="$1";

	outLog "Pulling new revision into test environment from old version ...";

	if [ "$OLD_VERSION" = "NA" ]; then
		outLog "Old version doesn't exist!";
                echo "";
                return 0
        fi

	outLog "Old Version: $OLD_VERSION";

	split '.' $OLD_VERSION;
	return_arr[3]="${test_BRANCH^^}";

	echo "$(join . ${return_arr[@]})"
}

pullRevisionIntoProduction() {
        local OLD_VERSION="$1";

	outLog "Pulling new revision into production environment from old version ...";

	if [ "$OLD_VERSION" = "NA" ]; then
		outLog "Old version doesn't exist!";
                echo "";
                return 0
        fi

	outLog "Old Version: $OLD_VERSION";

        split '.' $OLD_VERSION;
        return_arr[3]='';

        echo "$(join . ${return_arr[@]})"
}

generateChangeLog() {
	local REVISION_TYPE="$1";
	local REVISION="$(echo $2 | sed 's/\('.'[A-Z]\+\)$//g')";

	local MAJOR="$(echo $REVISION | sed 's/\('.'[0-9]\+'.'[0-9]\+\)$/.0/g')";
	local CHANGELOG="./CHANGELOG.md";
	local TEMP="./.tmp";
	local HISTORY="$(git rev-list --ancestry-path HEAD ^latest)";

	outLog "Generating CHANGELOG ...";
	outLog "Revision Type: $REVISION_TYPE";
	outLog "Minor Revision: $REVISION";
	outLog "Major Revision: $MAJOR";
	outLog "CHANGELOG File: $CHANGELOG";
	outLog "Total Commits: $(echo $HISTORY | wc -w)";

	outLog "Logging changes:";

	echo "# CHANGELOG<br>$MAJOR" > $TEMP;

	echo "## $REVISION" >> $TEMP;
	while read -r commit; do
		local DATE="$(git show -s --format=%ad --date=short $commit)";
		local AUTHOR="$(git show -s --format="%an [%ae]" $commit)";
		local MESSAGE="$(git show -s --format=%s $commit | sed 's/^\([A-Z]\+'-'[0-9]\+\)\?//g' | sed 's/\(#major\|#minor\)\?//g' | sed 's/  / /g' | sed -e 's/^ *//' -e 's/ *$//')";

		if [[ ${MESSAGE,,} == "add "* ]] || [[ ${MESSAGE,,} == "update "* ]] || [[ ${MESSAGE,,} == "change "* ]] || [[ ${MESSAGE,,} == "remove "* ]] ||
		[[ ${MESSAGE,,} == "replace "* ]] || [[ ${MESSAGE,,} == "revert "* ]] || [[ ${MESSAGE,,} == "fix "* ]]; then
			outLog "$DATE $MESSAGE | $AUTHOR";
			echo "- **$DATE** $MESSAGE | ***$AUTHOR***" >> $TEMP;
		fi
	done <<< "$HISTORY"

	outLog "Changes logged."

	if [ "$REVISION_TYPE" != "major" ] && [ -f $CHANGELOG ]; then
		tail -n +3 $CHANGELOG >> $TEMP;
	fi

	mv -f $TEMP $CHANGELOG;

	git add $CHANGELOG;
	git commit -m "${REVISION_TYPE^^} $REVISION Update CHANGELOG.md"
}

tagRelease() {
	local REVISION_TYPE="$1";
	local REVISION="$2";

	local MESSAGE="${REVISION_TYPE^^} $REVISION";

	outLog "Tagging new release ...";
	outLog "Revision Type: $REVISION_TYPE";
	outLog "Revision: $REVISION";
	outLog "Annotated Message: $MESSAGE";

	git tag -a "v$REVISION" -m "$MESSAGE";
	git tag -f latest
}

pushToOrigin() {
	outLog "Pushing changes to origin ...";

	git push 2> /dev/null;
	git push origin :latest 2> /dev/null;
	git push --tags 2> /dev/null;

	outLog "Push successful.";
}

outLog "Production Branch: $PROD_BRANCH";
outLog "Test Branch: $TEST_BRANCH";
outLog "Dev Branch: $DEV_BRANCH";

BRANCH="$(git branch --show-current)";
outLog "Current branch: $BRANCH";

REVISION="$(getLatestRevision)";
outLog "Latest Revision: $REVISION";

if [ -z "$REVISION" ]; then
	outLog "Tag version failed! Version must exist at :latest";
	exit 32;
fi

if [ "$REVISION" != "NA" ]; then
	REVISION_TYPE="$(getRevisionType)";
else
	REVISION_TYPE="major";
fi
outLog "Revision Type: $REVISION_TYPE";

if [ "$BRANCH" = "$DEV_BRANCH" ]; then
	outLog "Releasing for dev.";
	NEW_REVISION="$(getNewRevision $REVISION_TYPE $REVISION)";
	IS_PRERELEASE='true';

	generateChangeLog $REVISION_TYPE $NEW_REVISION;
elif [ "$BRANCH" = "$TEST_BRANCH" ]; then
	outLog "Releasing for test.";
	NEW_REVISION="$(pullRevisionIntoTest $REVISION)";
	IS_PRERELEASE='true';

	if [ -z "$NEW_REVISION" ]; then
                outLog "Tag version failed! :latest must exist when pulling into '$TEST_BRANCH'";
                exit 64;
        fi
elif [ "$BRANCH" = "$PROD_BRANCH" ]; then
	outLog "Releasing for production.";
	NEW_REVISION="$(pullRevisionIntoProduction $REVISION)";
	IS_PRERELEASE='false';

	if [ -z "$NEW_REVISION" ]; then
                outLog "Tag version failed! :latest must exist when pulling into '$PROD_BRANCH'";
                exit 64;
        fi
else
	outLog "Tag version failed! Unknown branch '$BRANCH'";
	exit 128;
fi
outLog "New Revision: $NEW_REVISION";

tagRelease $REVISION_TYPE $NEW_REVISION;
pushToOrigin;

outLog "Tag version complete.";
outLog "Output: $NEW_REVISION";
echo "::set-output name=revision::$NEW_REVISION";
echo "::set-output name=is-prerelease::$IS_PRERELEASE"
