<template>
  <div v-if="currentNotes.length > 0" :class="`c-instructor-note-app-${appId}`">
    <div
      v-for="note in currentNotes"
      :key="note.id"
      class="ns-music-v1">
      <div data-content-type="instructor_activity_note">
        <ActivityNote
          :ref="`ref-note-${note.id}`"
          :note="note"
          @deleted="removeNote" />
      </div>
    </div>
  </div>
</template>

<script>
  import { reactive } from 'vue';
  import ActivityNote from './ActivityNote';

  const useActivityNotes = (currentNotes) => {
    const removeNote = (id) => {
      const note = currentNotes.find((note) => note.id === id);
      currentNotes.splice(currentNotes.indexOf(note), 1);
    };

    const addNote = (note) => {
      currentNotes.push(note);
    };
    return { removeNote, addNote };
  };

  export default {
    name: 'ActivityNotes',
    components: { ActivityNote },
    props: {
      notes: {
        type: Array,
        default: () => [],
      },
      appId: {
        type: String,
        default: '',
      },

    },
    setup(props) {
      const { notes } = props;
      const { appId } = props;
      const currentNotes = reactive(notes.slice());

      const { removeNote, addNote } = useActivityNotes(currentNotes);

      return {
        currentNotes, appId, removeNote, addNote,
      };
    },
  };
</script>
