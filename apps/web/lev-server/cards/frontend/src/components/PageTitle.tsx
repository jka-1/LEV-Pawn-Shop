type PageTitleProps = {
  text?: string;
  className?: string;
  id?: string;
};

export default function PageTitle({ text = 'LEV', className = '', id = 'title' }: PageTitleProps) {
  return (
    <h1 id={id} className={className} aria-label={text}>
      {text}
    </h1>
  );
}
