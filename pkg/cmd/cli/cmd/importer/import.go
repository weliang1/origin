package importer

import (
	"fmt"
	"io"

	"github.com/spf13/cobra"

	cmdutil "github.com/openshift/origin/pkg/cmd/util"
	"github.com/openshift/origin/pkg/cmd/util/clientcmd"
)

const (
	importLong = `
Import outside applications into OpenShift

These commands assist in bringing existing applications into OpenShift.`
)

// NewCmdImport exposes commands for modifying objects.
func NewCmdImport(fullName string, f *clientcmd.Factory, in io.Reader, out, errout io.Writer) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "import COMMAND",
		Short: "Commands that import applications",
		Long:  importLong,
		Run:   cmdutil.DefaultSubCommandRun(out),
	}

	name := fmt.Sprintf("%s import", fullName)

	cmd.AddCommand(NewCmdDockerCompose(name, f, in, out, errout))
	return cmd
}
