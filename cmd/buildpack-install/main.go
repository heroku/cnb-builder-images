package main

import (
	"errors"
	"flag"
	"os"
	"path/filepath"
	"fmt"
	"strings"
	"github.com/BurntSushi/toml"
)

var (
	buildpacksDir     string
	orderPath         string
	inputBuildpackDir string
	latest            bool
)

type ErrorFail struct {
	Err    error
	Code   int
	Action []string
}

func (e *ErrorFail) Error() string {
	message := "failed to " + strings.Join(e.Action, " ")
	if e.Err == nil {
		return message
	}
	return fmt.Sprintf("%s: %s", message, e.Err)
}

func failErr(err error, action ...string) error {
	code := 1
	if err, ok := err.(*ErrorFail); ok {
		code = err.Code
	}
	return failErrCode(err, code, action...)
}

func failErrCode(err error, code int, action ...string) error {
	return &ErrorFail{Err: err, Code: code, Action: action}
}

func exit(err error) {
	if err == nil {
		os.Exit(0)
	}
	fmt.Printf("Error: %s\n", err)
	if err, ok := err.(*ErrorFail); ok {
		os.Exit(err.Code)
	}
	os.Exit(1)
}

type Buildpack struct {
	ID      string `toml:"id"`
	URI     string `toml:"uri"`
	Dir     string
	Version string `toml:"version"`
}

func (b *Buildpack) escapedID() string {
	return strings.Replace(b.ID, "/", "_", -1)
}

type BuildpackTOML struct {
	Buildpack Buildpack `toml:"buildpack"`
}

func init() {
	flag.StringVar(&inputBuildpackDir, "buildpack", "", "local path of the buildpack to install")
	flag.BoolVar(&latest, "latest", false, "true if this is the latest version of the buildpack")
	flag.StringVar(&buildpacksDir, "buildpacks", "/buildpacks", "path to buildpacks directory")
	flag.StringVar(&orderPath, "order", "/buildpacks/order.toml", "path to order.toml")
}

func main() {
	flag.Parse()
	if flag.NArg() != 0 {
		exit(errors.New("failed to parse arguments"))
	}

	exit(install())
}

func install() error {
	var buildpackTOML BuildpackTOML
	_, err := toml.DecodeFile(filepath.Join(inputBuildpackDir, "buildpack.toml"), &buildpackTOML)
	if err != nil {
		return failErr(err, "read buildpack metadata file")
	}

	metadata := buildpackTOML.Buildpack
	buildpackDirName := filepath.Base(inputBuildpackDir)
	outputBuildpackDir := filepath.Join(buildpacksDir, buildpackDirName, metadata.Version)
	err = os.MkdirAll(outputBuildpackDir, os.ModePerm)
	if err != nil {
		return failErr(err, "creating buildpack directory")
	}

	if err := os.Rename(inputBuildpackDir, outputBuildpackDir); err != nil {
		return failErr(err, "installing buildpack directory")
	}

	//if latest {
	//	latestDir := filepath.Join(buildpacksDir, metadata.ID, "latest")
	//	fileInfo, err := os.Lstat(latestDir)
	//	if !os.IsNotExist(err) {
	//		if fileInfo.Mode()&os.ModeSymlink == os.ModeSymlink {
	//			err := os.Remove(latestDir)
	//			if err != nil {
	//				return FailErr(err, "create latest symlink")
	//			}
	//		}
	//	}
	//	os.Symlink(outputBuildpackDir, latestDir)
	//}
	//
	//buildpacks, err := lifecycle.NewBuildpackMap(buildpacksDir)
	//if err != nil {
	//	return FailErr(err, "read buildpack directory")
	//}

	//order, err := buildpacks.ReadOrder(orderPath)
	//if err != nil {
	//	return FailErr(err, "read buildpack order file")
	//}

	// TODO append to order.toml
	f, err := os.OpenFile(orderPath, os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		return failErr(err, "opening order.toml")
	}
	defer f.Close()

	groupTemplate :=`
[[groups]]
buildpacks = [ { id = "%s", version = "%s" } ]
`
	_, err = f.WriteString(fmt.Sprintf(groupTemplate, metadata.ID, metadata.Version))
	if err != nil {
		return failErr(err, "writing to order.toml")
	}

	return nil
}