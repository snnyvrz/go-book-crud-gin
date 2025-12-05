export default {
    "*.{js,mjs,ts,tsx}": ["bun x eslint --fix", "bun x prettier --write"],

    "*.go": (files) => [
        ...files.map((f) => `go fix ${f}`),
        `gofmt -w ${files.join(" ")}`,
        "cd apps/books-service && go vet ./...",
    ],

    "*.sh": ["shfmt -ci -i 4 -w"],

    "*.{json,md,css,scss,html}": ["bun x prettier --write"],

    "*.{yml,yaml}": (files) =>
        files
            .filter((file) => !file.match(/^charts\/[^/]+\/templates\//))
            .map((file) => `bun x prettier --write ${file}`),

    "charts/**": ["scripts/lint-helm.sh"],
};
