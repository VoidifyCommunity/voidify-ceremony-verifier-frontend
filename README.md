# Voidify Ceremony IPFS Builder

IPFS hash generation script for the Voidify trusted-setup ceremony frontend.

Works on any platform (Linux, Windows, MacOS) if the Docker Desktop is installed.

## TL;DR

Script based on https://notes.ethereum.org/@GW1ZUbNKR5iRjjKYx6_dJQ/Bk8zsJ9xj


## How to use

1. Build the docker image

```bash
docker build -t voidify-ceremony-frontend .
```

2. Check the generated IPFS hash

```bash
docker container run --rm -it --entrypoint cat voidify-ceremony-frontend /app/ipfs_hash.txt
```

## Verifying the deployed CID

The live frontend is published to ENS at `ceremony.voidifycto.eth` and served
through the eth.limo gateway at https://ceremony.voidifycto.eth.limo. To
confirm the deployment matches the build above, look up the CID published on
ENS and compare it byte-for-byte to the `ipfs_hash.txt` you just generated.

Open https://app.ens.domains/ceremony.voidifycto.eth in a browser and check the
**Records** tab — the `contenthash` field shows the IPFS CID currently served.

You can also open that CID directly through any public IPFS gateway, for
example dweb.link:

> `https://<CID>.ipfs.dweb.link/`

A match means the deployed site is byte-identical to the build this Dockerfile
reproduces from the pinned GitHub commit.

## (Optional) Add built frontend to IPFS Desktop

First, install the latest IPFS Desktop.

Then, build the docker image and run the following command

```bash
docker container run --rm voidify-ceremony-frontend
```

You can now access the frontend on your local IPFS gateway through the following

http://localhost:8080/ipfs/content_hash_here
