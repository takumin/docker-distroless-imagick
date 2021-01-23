package main

import (
	"log"

	"gopkg.in/gographics/imagick.v2/imagick"
)

func main() {
	imagick.Initialize()
	defer imagick.Terminate()

	mw := imagick.NewMagickWand()
	defer mw.Destroy()

	if err := mw.ReadImage("logo:"); err != nil {
		panic(err)
	}

	if err := mw.WriteImage("logo.pgm"); err != nil {
		panic(err)
	}

	if err := mw.ReadImage("logo.pgm"); err != nil {
		panic(err)
	}

	if err := mw.WriteImage("logo.jpg"); err != nil {
		panic(err)
	}

	log.Println("Generated logo.pgm and logo.jpg")
}
