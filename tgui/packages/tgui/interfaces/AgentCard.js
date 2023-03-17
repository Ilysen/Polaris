import { useBackend } from "../backend";
import { Button, Section, Table } from "../components";
import { Window } from "../layouts";

export const AgentCard = (props, context) => {
  const { act, data } = useBackend(context);

  const {
    entries,
    electronic_warfare,
  } = data;

  return (
    <Window width={550} height={400} theme="syndicate">
      <Window.Content>
        <Section title="Info">
          <Table>
            {entries.map(a => (
              <Table.Row key={a.name}>
                <Table.Cell>
                  {a.name}:
                </Table.Cell>
                <Table.Cell>
                  <Button.Input
                    fluid
                    onCommit={(e, value) => act(a.name.toLowerCase().replace(/ /g, ""), { new_value: value })}
                    content={a.value} />
                </Table.Cell>
              </Table.Row>
            ))}
          </Table>
          <br />
          <Button
            icon="id-card"
            tooltip="Change the card's visual appearance to something else."
            tooltipPosition="top"
            onClick={() => act("appearance")}>
            Change Sprite
          </Button>
          <Button
            icon="portrait"
            tooltip="Update the card's photo to one based on your current appearance."
            tooltipPosition="top"
            onClick={() => act("photo")}>
            Update Photo
          </Button>
          <Button
            icon="eraser"
            tooltip="Clear all data, including access and ownership, from this card."
            tooltipPosition="top"
            onClick={() => act("factory_reset")}>
            Factory Reset
          </Button>
        </Section>
        <Section title="Electronic Warfare">
          <Button.Checkbox
            checked={electronic_warfare}
            content={electronic_warfare
              ? "Electronic warfare is enabled. This will prevent you from being tracked by the AI."
              : "Electronic warfare is disabled."}
            onClick={() => act("electronic_warfare")} />
        </Section>
      </Window.Content>
    </Window>
  );
};
