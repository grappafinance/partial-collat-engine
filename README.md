<div align="center">
  <h1 > Partial Collat Engine </h1>
  <img height=60 src="https://i.imgur.com/vSIO8xJ.png"/>
  <br/>
  <br/>
  <a href="https://github.com/foundry-rs/foundry"><img src="https://img.shields.io/static/v1?label=foundry-rs&message=foundry&color=blue&logo=github"/></a>
  <a href=https://github.com/grappafinance/partial-collat-engine/actions/workflows/CI.yml""><img src="https://github.com/grappafinance/partial-collat-engine/actions/workflows/CI.yml/badge.svg?branch=master"> </a>
  <a href="https://codecov.io/gh/grappafinance/partial-collat-engine" >
<img src="https://codecov.io/gh/grappafinance/partial-collat-engine/branch/master/graph/badge.svg?token=ZDZJSA9AUT"/>
</a>
  
</div>

## Get Started

```shell
forge build
forge test
```

For auto linting and running gas snapshot, you will also need to setup npm environment, and install husky hooks

```shell
# install yarn dependencies
yarn
# install hooks
npx husky install
```

### Test locally

```shell
forge test
```

### Run Coverage

```shell
forge coverage
```

### Linting

```shell
forge fmt
```
