import { CodegenConfig } from "@graphql-codegen/cli";
import { getPublicTokenHeaders, getStorefrontApiUrl } from "./src/lib/storefront.ts";

const config: CodegenConfig = {
  overwrite: true,
  ignoreNoDocuments: true,
  documents: ["./src/**/*.{ts,tsx}"],
  // schema: {
  //   [getStorefrontApiUrl()]: {
  //     headers: getPublicTokenHeaders(),
  //   },
  // },
  schema: "./src/lib/graphql/schema.gql",
  generates: {
    ["./src/lib/graphql/"]: {
      preset: "client",
      config: {
        documentMode: "string",
      },
    },
    "./src/lib/graphql/schema.gql": {
      plugins: ["schema-ast"],
      config: {
        includeDirectives: true,
      },
    },
  },
};

export default config;
