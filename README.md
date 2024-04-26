# flightctl-demos

This repo contains a series of demos showcasing the edge management capabilities of the flightctl project.


## Bootc Agent Images

The `bootc-agent-images` folder contains recipes to build two flavors of bootc images. [Bootc](https://github.com/containers/bootc) provides transactional, in-place operating system images using OCI container images.

This repository provides a recipe for a Fedora ELN based image and a Centos 9 Stream based image, both, with the flightctl agent installed in the image.

The config.yaml is pointing at the public instance of the FlightCtl service. However, in order to be able to do the enrollment, some files are needed such as CA and enrollment keypair. Please, ask the team for these files in order to produce an operational device agent against the public service. If you have your own instance of FlightCtl, modify the config.yaml file and add your own files.

In addition to this, both Containerfiles contain a commented section so you can add your SSH public key. Add your ssh key, uncomment and modify that section to enable that build step.

We have created Makefile targets to facilitate the build process. Execute the following command to build and push the image of your choice:

```
make bootc-fedora QUAYUSER=$yourownquayuser
````

or

```
make bootc-centos QUAYUSER=$yourownquayuser
```

or

```
make bootc-rhel QUAYUSER=$yourownquayuser
```


In order to make the deployment of this image easy, you can convert it to QCOW2 format and use it as a raw disk in Libvirt. The following command will create a file called disk.qcow2 within the output folder:

```
make qcow2-bootc flavor={fedora,centos,rhel}
```

Also you can create a raw image to burn to the device disk with:

```
make raw-bootc QUAYUSER=$yourownquayuser flavor={fedora,centos,rhel}
```