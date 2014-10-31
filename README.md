BOSH Release for Boundary Meter
===============================

A BOSH release to add a Boundary meter to each Job VM in an existing deployment.

Requirements
------------

-	Currently only supports Trusty stemcells.

Usage
-----

To use this bosh release, first upload it to your bosh:

```
bosh upload release releases/boundary-1.yml
```

Or upload the release from a public URL:

```
bosh upload release https://boundary-boshrelease.s3.amazonaws.com/boshrelease-boundary-1.tgz
```

Add the `boundary` release to the target deployment manifest:

```yaml
releases:
  - name: cf
    release: latest
  - name: boundary
    release: latest
```

Add the `boundary-meter` job template to each job in the target deployment manifest:

```yaml
jobs:
- name: runner_z1
  templates:
  - name: dea_next
    release: cf
  - name: boundary-meter
    release: boundary
```

Specify your API key in the global properties of the target deployment manifest:

```yaml
properties:
  boundary_meter:
    org_id_and_api_key: HERE
```
